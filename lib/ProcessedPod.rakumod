use v6.d;
use URI;
use LibCurl::Easy;
use RenderPod::Exceptions;
use RenderPod::Templating;
use PrettyDump;

grammar FC {
    # head is what is left of vertical bar, any non-vertical bar char, or empty
    # attrs is on right of bar
    # attrs is semicolon-separated list of things, can be double-quoted, or empty
    # What we care about are "head" and "meta" results
    # credit to @yary for this grammar

    # TODO rule instead of token? use .ws instead of \s or \h
    token TOP {
        <head>
        | <head> \s* '|' \s* <metas> \s*
        | ^ '|' \s* <metas> \s*
    }

    token head-word { <-[|\h]>+ }
    token head {
        <head-word>+ % \h+ | ''
    }

    token metas { <meta>* % [\s* ';' \s*] }
    # Semicolon-separated 0-or-more attr

    token meta-word { <-[;\"\h]>+ }
    # Anything without quote or solidus or space
    token meta-words { <meta-word>+ % \h* }
    token inside-quotes { <-[ " ]>+ }
    token meta-quoted {
        '"' ~ '"' <inside-quotes>*
    }
    token meta {
        <meta-words> | <meta-quoted>
    }
    # TODO: use "make" to pull inside-quotes value to meta
}

#| the name of the anchor at the top of a source file
constant DEFAULT_TOP = '___top';

class PodFile {
    # Variables relating to a specific pod file

    #| Text between =TITLE and first header, this is used to refer for textual placenames
    has Str $.front-matter is rw = 'preface';
    #| Name to be used in titles and files.
    has Str $.name is rw is default('UNNAMED') = 'UNNAMED';
    #| The string part of a Title.
    has Str $.title is rw is default('NO_TITLE') = 'NO_TITLE';
    #| A target associated with the Title Line
    has Str $.title-target is rw is default(DEFAULT_TOP) = DEFAULT_TOP;
    has Str $.subtitle is rw is default('') = '';
    #| should be path of original document, if supplied
    has Str $.path is rw is default('') = '';
    #| defaults to top, then becomes target for TITLE
    has Str $.top is rw is default(DEFAULT_TOP) = DEFAULT_TOP;

    # document level information

    #| language of pod file
    has Str $.lang is rw is default('en') = 'en';
    #| store data of semantic blocks
    #| information to be included in eg html header
    has @.raw-metadata;
    #| toc structure, collected and rendered separately to body
    has @.raw-toc;
    #| glossary structure
    has %.raw-glossary;
    #| footnotes structure
    has @.raw-footnotes;
    #| when source wrap is called
    has Str $.renderedtime is rw = '';
    #| the set of targets used in a rendering process
    has SetHash $.targets .= new;
    #| config data given to the first =begin pod line encountered
    #| there may be multiple pod blocks in a file, and they may be
    #| sequentially rendered.
    #| Can contain information about rendering footnotes/toc/glossary/meta
    #| Template used can be changed on a per file basis
    has %.pod-config-data is rw;
    #| Structure to collect links, eg. to test whether they all work
    has %.links;
    #| the templates used to render this file, copied from Templates role
    #| so that a record can be kept per pod-file, and per run
    has %.templates-used is rw;
    #| a copy of the output generated for the pod file
    has $.pod-output is rw;
    multi method gist(PodFile:U: ) { 'Undefined PodFile' }
    multi method gist(PodFile:D: Int :$output = 175 ) {
        my $temps-u = 'No templates used, has a render method been invoked?';
        if +%.templates-used.keys {
            $temps-u = "Hash=<{ %.templates-used.sort( *.value ).reverse.map( {.key ~ ': ' ~ .value } ).join(', ') }>"
        }
        qq:to/GIST/
        PodFile contains:
            front-matter => Str=｢{ $.front-matter }｣
            name => Str=｢{ $.name }｣
            title => Str=｢{ $.title }｣
            title-target => Str=｢{ $.title-target }｣
            subtitle => Str=｢{ $.subtitle }｣
            path => Str=｢{ $.path }｣
            top => Str=｢{ $.top }｣
            renderedtime => Str=｢{ $.renderedtime }｣
            lang => Str=｢{ $.lang }｣
            raw-metadata => { pretty-dump( $.raw-metadata, :pre-item-spacing("\n   "),:post-item-spacing("\n    "),
            :indent('  '), :post-separator-spacing("\n  ") )  }
            raw-toc => { pretty-dump($.raw-toc, :pre-item-spacing("\n   "),:post-item-spacing("\n    "),
               :indent('  '), :post-separator-spacing("\n  ")) }
            raw-glossary => { pretty-dump( $.raw-glossary, :pre-item-spacing("\n   "),:post-item-spacing("\n    "),
               :indent('  '), :post-separator-spacing("\n  ") )  }
            raw-footnotes => { pretty-dump( $.raw-footnotes, :pre-item-spacing("\n   "),:post-item-spacing("\n    "),
                :indent('  '), :post-separator-spacing("\n  ") )  }
            pod-config-data => { pretty-dump( $.pod-config-data, :pre-item-spacing("\n   "),:post-item-spacing("\n    "),
                :indent('  '), :post-separator-spacing("\n  ") )  }
            links => { pretty-dump( $.links, :pre-item-spacing("\n   "),:post-item-spacing("\n    "),
                :indent('  '), :post-separator-spacing("\n  ") )  }
            targets => <｢{ $.targets.keys.join('｣, ｢') }｣>
            templates-used => { $temps-u }
            pod-output => { with $!pod-output  { .substr(0, $output) ~ ( .chars > $output ?? "\n... (" ~ .chars - $output ~ ' more chars)' !! '') } }
        GIST
    }
}

class ProcessedPod does SetupTemplates {
    # information on file
    has PodFile $.pod-file .= new;

    # Output rendering information set by environment
    #| set to True eliminates meta data rendering
    has Bool $.no-meta is rw = False;
    #| set to True eliminates rendering of footnotes
    has Bool $.no-footnotes is rw = False;
    #| set to True to exclude TOC even if there are headers
    has Bool $.no-toc is rw = False;
    #| set to True to exclude Glossary even if there are internal anchors
    has Bool $.no-glossary is rw = False;

    # Output set by subclasses or collection

    #| default extension for saving to file
    #| should be set by subclasses
    has $.def-ext is rw is default('') = '';

    # Data relating to the processing of a Pod file

    # debugging
    #| outputs to STDERR information on processing
    has Bool $.debug is rw = False;
    #| outputs to STDERR more detail about errors.
    has Bool $.verbose is rw = False;

    # populated by process-pod method
    #| single process call
    has Str $.pod-body is rw;
    #| concatenation of multiple process calls
    has Str $.body is rw = '';
    #| metadata when rendered
    has Str $.metadata;
    #| rendered toc
    has Str $.toc;
    #| rendered glossary
    has Str $.glossary;
    #| rendered footnotes
    has Str $.footnotes;
    #| A pod line may have no config data, so flag if pod block processed
    has Bool $.pod-block-processed is rw = False;

    #| custom blocks
    has @.custom = ();
    #| plugin data, accessible via add/get plugin-data
    has %!plugin-data = {};

    # variables to manage Pod state, where rendering is dependent on local context
    #| for multilevel lists
    has @.itemlist;
    #| used to register state when processing a definition list
    has Bool $!in-defn-list = False;

    #| the Config stack
    has @.config-stack ;
    #| contains the configuration for the outer pod/rakudoc block
    #| :block-scope adds the %extra info to the enclosing block scope, needed for a config directive
    #| without :block-scope, the extra info is added to the current block scope
    multi method config { @.config-stack[ *-1 ].clone }
    multi method config( %extra ) { for %extra.kv { @.config-stack[ *-1 ]{ $^a } = $^b } }
    multi method config( %extra, :$block-scope! ) {
        return unless $block-scope;
        if @!config-stack.elems {
            my $index = @!config-stack.elems eq 1 ?? 0 !! @!config-stack.elems - 2;
            for %extra.kv { @!config-stack[ $index ]{ $^a } = $^b }
        }
        else {
            @!config-stack[0] = %extra
        }
    }

    my enum Context <None Heading HTML Raw Preformatted InCodeBlock>;

    submethod TWEAK(:$rakopts) {
        with %*ENV<RAKOPTS> // $rakopts {
            $!no-toc = ?m/:i 'No' \-? 'TOC'/;
            $!no-footnotes = ?m/:i 'No' \-? 'Foot'/;
            $!no-glossary = ?m/:i 'No' \-? 'Glos'/;
            $!no-meta = ?m/:i 'No' \-? 'Meta'/;
        }
        note "Debug is { $!debug ?? 'ON' !! 'OFF' } and Verbose is { $!verbose ?? 'ON' !! 'OFF' }."
        if $!debug or $!verbose;
    }

    # The next function is placed here because it may need to be over-ridden. (see Pod::To::Markdown)

    #| rewrites targets (link/footnotes destinations) to be made unique and to be canonised depending on the output format
    #| takes the candidate name, and whether it should be unique
    #| returns with the canonised link name
    #| if unique, then adds target to target set, otherwise does not add.
    method rewrite-target(Str $candidate-name is copy, :$unique --> Str) {
        # target names inside the POD file, eg., headers, glossary, footnotes
        # function is called to canonise the target name and to ensure - if necessary - that
        # the target name used in the link is unique.
        # This method uses the default algorithm for HTML and POD
        # It may need to be over-ridden, eg., for MarkDown which uses a different targeting function.
        # $unique means register target to ensure unique ones

        return DEFAULT_TOP if $candidate-name eq DEFAULT_TOP;
        # don't rewrite the top

        $candidate-name = $candidate-name.subst(/\s+/, '_', :g);
        if $unique {
            if $!pod-file.targets{$candidate-name} {
                $candidate-name ~= '_0' unless $!pod-file.targets{$candidate-name ~ '_0'};
                # will continue to loop until a unique name is found
                ++$candidate-name while $!pod-file.targets{$candidate-name};
            }
            $!pod-file.targets{$candidate-name}++;
        }
        $candidate-name
    }

    # Methods relating to customisation
    method add-plugin(Str $plugin-name,
                      :$path = $plugin-name,
                      :$template-raku = "templates.raku",
                      :$custom-raku = "blocks.raku",
                      :%config is copy,
                      :$protect-name = True
                      ) {
        X::ProcessedPod::NamespaceConflict.new(:name-space($plugin-name)).throw
            if $protect-name and %!plugin-data{$plugin-name}:exists;
        with %config {
            %config<path> = $path
        }
        else {
            %config = %( :$path )
        }
        self.modify-templates( $template-raku, :$path, :plugin ) if $template-raku;
        self.add-custom( $custom-raku, :$path ) if $custom-raku;
        self.add-data( $plugin-name, %config, :$protect-name )
    }
    multi method add-custom( Str $filename, :$path = $filename ) {
        return unless "$path/$filename".IO.f;
        my @blocks = indir($path, { EVALFILE $filename } );
        X::ProcessedPod::NoBlocksAdded.new(:$filename,:$path).throw
            unless +@blocks;
        self.add-custom( @blocks );
    }
    multi method add-custom( @blocks ) {
        for @blocks { @!custom.append( $_ ) if $_ ~~ Str:D };
    }
    method add-data($name-space, $data-object, :$protect-name = True ) {
        return unless $data-object;
        X::ProcessedPod::NamespaceConflict.new(:$name-space).throw
            if $protect-name and %!plugin-data{$name-space}:exists;
        %!plugin-data{$name-space} = $data-object
    }
    method get-data($name-space) {
        return Nil unless %!plugin-data{$name-space}:exists;
        %!plugin-data{$name-space}
    }
    method plugin-datakeys { %!plugin-data.keys }

    #| process the pod block or tree passed to it, and concatenates it to previous pod tree
    #| returns a string representation of the tree in the required format
    method process-pod($pod --> Str) {
        die 'cannot process an undefined Pod-Block' unless $pod.defined or $pod ~~ Array;
        $.config( %(
            :name($!pod-file.name),
            :lang($!pod-file.lang),
            :path($!pod-file.path),
        ), :block-scope );
        $!pod-body = [~] gather for $pod.list { take self.handle($_, 0 , Context::None ) };
        # returns accumulated pod-bodies
        $!body ~= $!pod-body;
    }

    #| renders a pod tree, but probably a block
    #| returns only the pod that was passed
    method render-block($pod --> Str) {
        self.process-pod($pod);
        $!pod-body
        # returns only most recent pod-body
    }

    #| renders the whole pod tree
    #| is actually an alias to process-pod
    method render-tree($pod --> Str) {
        # an alias for a consistent naming system
        self.process-pod($pod);
    }

    #| deletes any previously processed pod, keeping the template engine cache
    #| does not change flags relating to highlighting
    method emit-and-renew-processed-state( --> PodFile ) {
        my PodFile $old = $!pod-file;
        $old.templates-used = %($.templs-used);
        $old.pod-output = $!body;
        $!pod-file .= new;

        #clean out the variables, whilst keeping the Templating engine cache.
        $!metadata = $!toc = $!glossary = $!footnotes = $!body = Nil;
        @!config-stack = Nil;
        $!pod-block-processed = False;
        $.reset-used; # provided by Role
        $old
    }

    # These are the rendering functions for the file and the file structures.
    # The first pass creates the rendering for a pod tree, and collects data for TOC/glossary/footnotes
    # Then the structures are rendered after the body has been prepared.

    #| saves the rendered pod tree as a file, and its document structures, uses source wrap
    #| filename defaults to the name of the pod tree, and ext defaults to html
    method file-wrap(:$filename = $.pod-file.name, :$ext = $.def-ext, :$dir = '') {
        ($dir ~ ('/' if $dir) ~ $filename ~ ('.' if $ext ne '') ~ $ext).IO.spurt: self.source-wrap
    }

    #| renders all of the document structures, and wraps them and the body
    #| uses the source-wrap template
    method source-wrap(--> Str) {
        $!pod-file.renderedtime = now.DateTime.utc.truncated-to('seconds').Str;
        self.render-structures;
        self.rendition('source-wrap', {
            :title($!pod-file.title),
            :title-target($!pod-file.title-target),
            :subtitle($!pod-file.subtitle),
            :$!metadata,
            :$!toc,
            :$!glossary,
            :$!footnotes,
            :$!body,
            :config( $.config ),
            :renderedtime($!pod-file.renderedtime),
        })
    }

    method render-structures {
        $!metadata = self.render-meta;
        $!toc = self.render-toc;
        $!glossary = self.render-glossary;
        $!footnotes = self.render-footnotes;
    }

    #| renders only the toc
    method render-toc(--> Str) {
        # if no headers in pod, then no need to include a TOC
        return '' if (!?$!pod-file.raw-toc or $.no-toc or $.pod-file.pod-config-data<no-toc>);
        my @filtered = $!pod-file.raw-toc.grep({ !(.<is-title>) });
        return '' unless +@filtered;
        self.rendition('toc', %( :toc([@filtered])));
    }

    #| renders only the glossary
    method render-glossary(-->Str) {
        return '' if (!?$!pod-file.raw-glossary.keys or $.no-glossary or $.pod-file.pod-config-data<no-glossary>);
        #No render without any keys
        my @filtered = [gather for $!pod-file.raw-glossary.sort { take %(:text(.key), :refs([.value.sort])) }];
        return '' unless +@filtered;
        self.rendition('glossary', %( :glossary(@filtered)))
    }

    #| renders only the footnotes
    method render-footnotes(--> Str) {
        return '' if (!?$!pod-file.raw-footnotes or $!no-footnotes or $.pod-file.pod-config-data<no-footnotes>);
        # no rendering of code if no footnotes
        self.rendition('footnotes', %( :notes($!pod-file.raw-footnotes)))
    }

    #| renders on the meta data
    method render-meta(--> Str) {
        return '' if (!?$!pod-file.raw-metadata or $!no-meta or $.pod-file.pod-config-data<no-meta>);
        self.rendition('meta',
            %( :meta(
                $!pod-file.raw-metadata
            ))
        )
    }

    # methods to collect page component data

    #| registers a header or title in the toc structure
    #| is-title is true for TITLE and SUBTITLE blocks, false otherwise
    method register-toc(:$level!, :$text!, Bool :$is-title = False, Bool :$unique = False, Bool :$toc = True --> Str) {
        my $target = self.rewrite-target($text, :unique($is-title or $unique));
        # if a title (TITLE) then it must be unique
        $!pod-file.raw-toc.push: %( :$level, :$text, :$target, :$is-title ) if $toc;
        $target
    }

    method register-glossary(Str $text, @entries, Bool $is-header --> Str) {
        my $target;
        # Original Pod::To::HTML href
        # my $index-name-attr =
        #    qq[index-entry{ @indices ?? '-' !! '' }{ @indices.join('-') }{ $index-text ?? '-' !! '' }$index-text]
        #    .subst('_', '__', :g).subst(' ', '_', :g);
        $target = 'index-entry';
        if @entries {
            if all(@entries>>.elems.map(* == 2)) {
                $target ~= '-' ~ @entries>>[1..*].join('-')
            }
            else {
                $target ~= '-' ~ @entries.join('-')
            }
        }
        $target ~= '-' ~ $text.subst(/ '<' '/'* 'code>' /,'',:g ) if $text;
        $target .= subst('_', '__', :g);
        $target .= subst(' ', '_', :g);
        $target = self.rewrite-target($target, :unique);
        # Place information is needed when a glossary is constructed without a return anchor reference,
        # so the most recent header is used
        # Add is-header flag to glossary entry
        my $place = +$.pod-file.raw-toc ?? $.pod-file.raw-toc[*- 1]<text> !! $!pod-file.front-matter;
        if @entries {
            for @entries {
                $.pod-file.raw-glossary{.[0]} = Array unless $.pod-file.raw-glossary{.[0]}:exists;
                if .elems > 1 { $.pod-file.raw-glossary{.[0]}.push: %(:$target, :place(.[1]), :$is-header) }
                else { $.pod-file.raw-glossary{.[0]}.push: %(:$target, :$place, :$is-header) }
            }
        }
        else {
            # if no entries, then there must be $text to get here
            $.pod-file.raw-glossary{$text} = Array unless $.pod-file.raw-glossary{$text}:exists;
            $.pod-file.raw-glossary{$text}.push: %(:$target, :$place, :$is-header);
        }
        $target
    }

    method register-link(Str $entry, Str $link-label ) {
        return ($.pod-file.links{$entry}<target type place>, $link-label).flat
            if $.pod-file.links{$entry}:exists;
        # just return target if it exists
        # A link may be
        # - internal to the document so the target may need to be rewritten depending on output format
        # - to another documents with the same format (do not rewrite file name, template engine to handle extension), target has filename, maybe a place inside
        # - to an external source no rewrite, has http(s) schema
        given $entry {
            # remote links first, if # in link, that will be handled by destination
            when / ^ 'http://' | ^ 'https://' / {
                $.pod-file.links{$_} = %(
                    :target($_),
                    :$link-label,
                    :type<external>,
                    :place()
                )
            }
            # next deal with internal links
            when / ^ '#' $<tgt> = (.+) / {
                $.pod-file.links{$_} = %(
                    :target(),
                    :$link-label,
                    :type<internal>,
                    :place($.rewrite-target( ~$<tgt>, :!unique))
                );
            }
            when / (.+?) '#' (.+) $/ {
                my $place = ~$1;
                my $target = ~$0.subst(/'::'/, '/', :g); # only subst :: in file part
                $.pod-file.links{$_} = %(
                    :$target,
                    :$link-label,
                    :type<local>,
                    :$place
                );
            }
            when / '::' / {  # so no place inside file, which would have been dealt with above
                my $target = .subst(/'::'/,'/',:g );
                $.pod-file.links{$_} = %(
                    :$target,
                    :$link-label,
                    :type<local>,
                    :place()
                )
            }
            default  {
                $.pod-file.links{$_} = %(
                    :target($_),
                    :$link-label,
                    :type<local>,
                    :place()
                )
            }
        }
        $.pod-file.links{$entry}<target type place link-label>.flat
    }

    # A footnote structure is created storing both the target anchor (with the footnote text)
    # and the return anchor (with the text from which the footnote originates, to be used in the footnote
    # to return the cursor if desired).

    method register-footnote(:$text!, :$context --> Hash) {
        my $fnNumber = +$!pod-file.raw-footnotes + 1;
        my $fnTarget = self.rewrite-target("fn$fnNumber", :unique);
        my $retTarget = self.rewrite-target("fnret$fnNumber", :unique);
        $!pod-file.raw-footnotes.push: %( :$text, :$retTarget, :$fnNumber, :$fnTarget, :$context );
        (:$fnTarget, :$fnNumber, :$retTarget, :$context ).hash
    }

    # Pod specifies Meta data for use in an HTML header context, but it could be used in other
    # contexts, such as epub or pdf for the author, version, etc.

    method register-meta(:$name, :$value, :$caption = $name, :$level = 1 ) {
        $!pod-file.raw-metadata.push: %( :$name, :$value, :$caption, :$level )
    }

    # This is the routine called at the end of a Pod block and is used to determine whether the cursor
    # is in the context of a B<List> or B<Definition>, which may be recursively called.

    #| verifies whether a list has completed, otherwise adding items or definitions to the list
    #| completes list if the context indicates the end of a list
    #| returns the string representation of the block / list
    method completion(Int $in-level, Str $key, %params, Bool :$defn --> Str) {
        note "Completion with template ｢$key｣ list level $in-level definition list ｢$defn｣" if $!debug;
        note 'Templates used so far: ', $.templs-used if $!debug and $!verbose;
        # most blocks would end a list if it exists, so call with zero
        # but if no list, viz $in-level=0, or a defn list then just return.
        # this is an optimisation
        #return '' if $key eq 'zero' and (! +$in-level or ! $defn);
        my Str $rv = '';
        # first handle defn list because it doesn't have multiple levels
        # so do not need to consider recursive calls.
        # start and end of list handled by $!in-defn-list, inner Pod blocks handled by $defn
        if !$!in-defn-list and $key eq 'defn' {
            # start of defn list when no previous defn
            $!in-defn-list = True;
            $rv ~= $.rendition('dlist-start', %());
        }
        if $!in-defn-list and ! $defn and $key ne 'defn' {
            # end of defn list, when previous defn, not a block inside a defn, block after a defn
            $!in-defn-list = False;
            $rv ~= $.rendition('dlist-end', %());
        }
        my $top-level = @.itemlist.elems;
        =comment some renderers, eg. MarkDown, need to have an explicit nesting hint
        for the depth of the list to render list of lists correctly

        while $top-level > $in-level {
            if $top-level > 1 {
                @.itemlist[$top-level - 2][0] = '' unless @.itemlist[$top-level - 2][0]:exists;
                @.itemlist[$top-level - 2][*- 1] ~= self.rendition('list', %( :nesting($top-level - 1), :items(@.itemlist.pop)));
                note "Rendering with template ｢list｣ list level $in-level" if $!debug;
            }
            else {
                $rv ~= self.rendition('list', %( :0nesting, :items(@.itemlist.pop)));
                note "Rendering with template ｢list｣ list level $in-level" if $!debug;
            }
            $top-level = @.itemlist.elems
        }
        $rv ~= self.rendition($key, %params);
        note "Ending completion with rv: ", $rv.substr(0, 150), $rv.chars > 150 ?? "\n... (" ~ $rv.chars - 150 ~ ' more chars)' !! ''
            if $.debug and $.verbose;
        $rv
    }

    #| Strip out formatting code and links from a Title or Link
    multi sub recurse-until-str(Str:D $s) {
        $s
    }
    multi sub recurse-until-str(Pod::Block $n) {
        $n.contents>>.&recurse-until-str().join
    }

    proto method handle(|c) {
        note 'Node is ' ~ |c[0].^name
            ~ (|c[0].^can('name') ?? (' with name ｢' ~ |c[0].name) ~ '｣' !! '')
            ~ (|c[0].^can('type') ?? (' with type ｢' ~ |c[0].type) ~ '｣' !! '')
            if $.debug;
        @.config-stack.push: $.config;
        if $.verbose {
            note 'Scope config data is ' ~ $.config.raku;
            note 'Node config data is ' ~ |c[0].config.raku if |c[0].^can('config');
        }
        my $rv = {*}
        @.config-stack.pop;
        $rv
    }

    #| Handle processes Pod blocks, bare strings, and throws if a Nil
    multi method handle(Nil) {
        X::ProcessedPod::Unexpected-Nil.new.throw
    }
    #| handle strings within a Block, don't need to be escaped if HTML
    multi method handle(Str $node, Int $in-level, Context $context --> Str) {
        $.rendition((($context ~~ HTML | Raw ) or ( $context ~~ InCodeBlock and $.no-code-escape)) ?? 'raw' !! 'escaped', %( :contents(~$node)))
    }

    multi method handle(Pod::Block::Code $node, Int $in-level, Context $context = InCodeBlock, Bool :$defn = False,  --> Str) {
        # first completion is to flush a retained list before the contents of the block are processed
        my $retained-list = $.completion($in-level, 'zero', %(), :$defn );
        my $contents = [~] gather for $node.contents { take self.handle($_, $in-level, InCodeBlock, :$defn ) };
        my $template = $node.config<template> // 'block-code';
        my $name-space = $node.config<name-space> // $template;
        my $data = $_ with %!plugin-data{ $name-space };

        $retained-list
            ~ $.completion($in-level, 'block-code',
            %( :$contents,
               $node.config,
               "$name-space" => $data,
               :config(self.config),
            ), :$defn
        )
    }
    multi method handle(Pod::Block::Input $node, Int $in-level, Context $context = Preformatted, Bool :$defn = False,  --> Str) {
        # first completion is to flush a retained list before the contents of the block are processed
        my $retained-list = $.completion($in-level, 'zero', %(), :$defn );
        my $contents = [~] gather for $node.contents { take self.handle($_, $in-level, Preformatted, :$defn ) };
        my $template = $node.config<template> // 'input';
        my $name-space = $node.config<name-space> // $template;
        my $data = $_ with %!plugin-data{ $name-space };

        $retained-list
            ~ $.completion($in-level, $template,
            %( :$contents,
               $node.config,
               "$name-space" => $data,
               :config(self.config),
            ), :$defn
        )
    }
    multi method handle(Pod::Block::Output $node, Int $in-level, Context $context = Preformatted, Bool :$defn = False,  --> Str) {
        # first completion is to flush a retained list before the contents of the block are processed
        my $retained-list = $.completion($in-level, 'zero', %(), :$defn );
        my $contents = [~] gather for $node.contents { take self.handle($_, $in-level, Preformatted, :$defn ) };
        my $template = $node.config<template> // 'output';
        my $name-space = $node.config<name-space> // $template;
        my $data = $_ with %!plugin-data{ $name-space };

        $retained-list
            ~ $.completion($in-level, $template,
            %( :$contents,
               $node.config,
               "$name-space" => $data,
               :config(self.config),
            ), :$defn
        )
    }

    multi method handle(Pod::Block::Comment $node, Int $in-level, Context $context = None, Bool :$defn = False,  --> Str) {
        $.completion($in-level, 'zero', %(), :$defn )
                ~ $.completion($in-level, 'zero', %( :contents([~] gather for $node.contents {
            take self.handle($_, $in-level, $context, :$defn)
        })), :$defn)
    }

    multi method handle(Pod::Block::Declarator $node, Int $in-level, Context $context, Bool :$defn = False,  --> Str) {
        my $code;
        given $node.WHEREFORE {
            when Routine {
                $code = ~ $node.WHEREFORE.raku.comb(/ ^ .+? <before \{> /);
            }
            default {
                $code = $node.WHEREFORE.raku;
            }
        }
        my $target = $.register-glossary($code, [], False);
        $.completion($in-level, 'zero', %(), :$defn )
            ~ $.completion($in-level, 'declarator',
            %( :$code, :$target, :contents(~ $node.contents )), :$defn
            )
    }

    multi method handle(Pod::Block::Named $node, Int $in-level, Context $context = None, Bool :$defn = False,  --> Str) {
        my $target = $.register-toc(:1level, :text($node.name.tclc));
        my $template = $node.config<template> // 'unknown-name';
        my $name-space = $node.config<name-space> // $template // $node.name.lc;
        my $data = $_ with %!plugin-data{ $name-space };

        $.completion($in-level, 'zero', %(), :$defn )
            ~ $.completion($in-level, $template, %(
                :name($node.name),
                "$name-space" => $data,
                :$target,
                :1level,
                :contents([~] gather for $node.contents { take self.handle($_, $in-level, $context, :$defn ) }),
                :top($.pod-file.top),
                :config(self.config),
                $node.config
            ), :$defn
        )
    }

    multi method handle(Pod::Block::Named $node where .name ~~ /:i ^ 'pod' | 'rakudoc' $/, Int $in-level,
                        Context $context = None, Bool :$defn = False,  --> Str) {
        my $name = $.pod-file.top eq DEFAULT_TOP ?? DEFAULT_TOP !! 'pod';
        # DEFAULT_TOP, until TITLE changes it. Will fail if multiple pod without TITLE
        unless $.pod-block-processed {
            $.pod-file.pod-config-data = $node.config;
            $.config( $node.config, :block-scope );
            $.pod-block-processed = True;
            note "Processing first pod declaration in file { $.pod-file.path }" if $.debug;
        }
        $.config( $node.config );
        my $template = $node.config<template> // 'pod';
        my $name-space = $node.config<name-space> // $template;
        my $data = $_ with %!plugin-data{ $name-space };

        $.completion($in-level, $template, %(
            :$name,
            "$name-space" => $data,
            :config( $.config ),
            :contents([~] gather for $node.contents { take self.handle($_, $in-level, $context, :$defn) }),
            :tail($.completion( 0, 'zero', %(), :$defn ))
            ), :$defn
        )
    }

    # special case HTML for Pod::To::HTML compatibility
    multi method handle(Pod::Block::Named $node where $node.name ~~ /:i 'html' / , Int $in-level,
                        Context $context = None, Bool :$defn = False, --> Str) {
        $.completion($in-level, 'zero', %(), :$defn )
            ~ $.completion($in-level, 'raw', %( :contents([~] gather for $node.contents { take self.handle($_,
                $in-level, HTML, :$defn) }), $node.config
            ), :$defn
        )
    }

    # TITLE, SUBTITLE, META blocks are not included in Body
    multi method handle(Pod::Block::Named $node where .name eq 'TITLE', Int $in-level,
                        Context $context, Bool :$defn = False, --> Str) {
        $.pod-file.title = recurse-until-str($node);
        $.pod-file.title-target = $.pod-file.top = $.register-toc(:1level, :text($.pod-file.title), :is-title);
        $.completion($in-level, 'zero', %($node.config), :$defn )
        # if a list before TITLE this will be needed
    }

    multi method handle(Pod::Block::Named $node where .name eq 'SUBTITLE', Int $in-level,
                        Context $context, Bool :$defn = False, --> Str) {
        $.pod-file.subtitle = [~] gather for $node.contents { take self.handle($_, 0, None, :$defn) };
        $.completion(0, 'zero', %($node.config), :$defn )
        # we can't guarantee SUBTITLE will be after TITLE
    }

    # Semantic blocks other than above treat as head1
    multi method handle(Pod::Block::Named $node where .name ~~ / ^ <upper>+ $ /,
                        Int $in-level, Context $context, Bool :$defn = False, --> Str) {
        my $retained-list = $.completion($in-level, 'zero', %(), :$defn);
        # process before contents
        my $level;
        my Bool $toc;
        with $node.config<headlevel> {
            $level = abs($_);
            $toc = $level != 0;
        }
        else {
            with $node.config<toc> {
                $toc = $_;
                $level = 0 unless $toc;
            }
            else {
                $toc = True;
                $level = 1;
            }
        }
        $toc = ! $_ with $node.config<hidden>;
        $toc = False if $node.name ~~ any(<VERSION DESCRIPTION AUTHOR SUMMARY>);
        my $caption = $node.config<caption> // $node.name;
        # possibilities: :template or :name-space given in metadata
        # or SEMANTIC (viz. node.name) template in template hash
        my $semantic = $node.name if $.tmpl{ $node.name }:exists; # if doesn't exist then Any
        my $template = $node.config<template> // $semantic;
        my $name-space = $node.config<name-space> // $template // $node.name;
        my $data = $_ with %!plugin-data{ $name-space };
        my $target = $.register-toc( :$level, :text($caption), :$toc, :unique );
        my $contents = trim( [~] gather for $node.contents { take self.handle($_, $in-level, $context, :$defn) } );
        $contents ~= $.completion($in-level, 'zero', %(), :$defn );
        my $raw-contents = trim( [~] gather for $node.contents { take self.handle($_, $in-level, Context::Raw, :$defn) } );
        $raw-contents ~= $.completion($in-level, 'zero', %(), :$defn );
        my $rendered;
        with $template { # only defined if there is block name template, or template given
            $rendered = $.completion($in-level, $template, {
                :$level,
                :text($caption),
                :$target,
                :top($.pod-file.top),
                $name-space => $data,
                $node.config,
                :config(self.config),
                :$context,
                :$contents,
                :$raw-contents,
                }, :$defn
            )
        }
        else {
            $rendered = $.completion($in-level, 'heading', {
                :$level,
                :text($caption),
                :$target,
                :top($.pod-file.top),
                $name-space => $data,
                $node.config,
                :config(self.config),
                :$context,
                }, :$defn
            ) ~ $contents
        }
        $.register-meta(:name($node.name), :value($rendered), :$caption, :$level );
        if $node.config<hidden> or $node.name ~~ any(<VERSION DESCRIPTION AUTHOR SUMMARY>) {
            $rendered = ''
        }
        $retained-list ~ $rendered
    }

    multi method handle(Pod::Block::Named $node where .name.lc eq 'raw', Int $in-level,
                        Context $context = None, Bool :$defn = False,  --> Str) {
        $.completion($in-level, 'zero', %(), :$defn )
            ~ $.completion($in-level, 'raw',
            %( :contents([~] gather for $node.contents { take self.handle($_, $in-level, $context, :$defn) }),$node.config)
            , :$defn
        )
    }

    multi method handle(Pod::Block::Named $node where .name ~~ any( ( @.custom , <para Para nested Nested> ).flat ),
                        Int $in-level,
                        Context $context = None,
                        Bool :$defn = False,  --> Str) {
        my $level;
        my Bool $toc;
        with $node.config<headlevel> {
            $level = abs($_);
            $toc = $level != 0;
        }
        else {
            with $node.config<toc> {
                $toc = $_;
                $level = 0 unless $toc;
            }
            else {
                $toc = $node.name ne any(<para Para nested Nested>);
                $level = 1;
            }
        }
        my $target = '';
        my $caption = $node.config<caption> // recurse-until-str($node).tclc;
        $target = $.register-toc(:$level, :text($caption), :$toc);
        my $template = $node.config<template> // $node.name.lc;
        my $name-space = $node.config<name-space> // $template // $node.name.lc;
        my $data = $_ with %!plugin-data{ $name-space };
        my $unrendered-list = $.completion($in-level, 'zero', %(), :$defn );
        my $contents = [~] gather for $node.contents { take self.handle($_, $in-level, $context, :$defn) }
        $contents ~= $.completion($in-level, 'zero', %(), :$defn );
        my $raw-contents = [~] gather for $node.contents { take self.handle($_, $in-level, Raw, :$defn ) }
        $raw-contents ~= $.completion($in-level, 'zero', %(), :$defn );
        $unrendered-list ~ $.completion($in-level, $template, %(
                :$contents,
                $node.config,
                :$target,
                :$raw-contents,
                $name-space => $data,
                :config(self.config),
            ), :$defn
        )
    }

    multi method handle(Pod::Block::Para $node, Int $in-level, Context $context where *== Preformatted, Bool :$defn = False, --> Str) {
        $.completion($in-level, 'zero', %(), :$defn )
            ~ $.completion($in-level, 'raw',
            %( :contents([~] gather for $node.contents { take self.handle($_, $in-level, $context, :$defn) }),
               $node.config, :config(self.config),)
                , :$defn)

    }

    multi method handle(Pod::Block::Para $node, Int $in-level, Context $context, Bool :$defn = False,  --> Str) {
        note "Defn flag is $defn and context is $context" if $.verbose;
        $.completion($in-level, 'zero', %(), :$defn )
            ~ $.completion($in-level, ($defn || $context !~~ None ) ?? 'raw' !! 'para' ,
            %( :contents([~] gather for $node.contents { take self.handle($_, $in-level, $context) }),
               $node.config, :config(self.config), )
            , :$defn)
    }

    multi method handle(Pod::Block::Table $node, Int $in-level, Context $context, Bool :$defn = False, --> Str) {
        my $template = $node.config<template> // 'table';
        my @headers = gather for $node.headers { take self.handle($_, $in-level, $context) };
        $.completion($in-level, 'zero', %(), :$defn)
            ~ $.completion($in-level, $template, %(
                :caption($node.caption ?? $.handle($node.caption, $in-level, $context) !! ''),
                :headers(+@headers ?? %( :cells(@headers)) !! Nil),
                :rows([gather for $node.contents -> @r {
                    take %( :cells([gather for @r { take $.handle($_, $in-level, $context, :$defn) }]))
                }]),
                $node.config,
                :config(self.config),
                :$context,
            ),
            :$defn
        )
    }
    # RakuDoc makes row/column directives, but POD6 thinks they are blocks, so metadata are in contents
    sub grid-directive-config( $instruction --> Hash ) {
        my %opts;
        for <label header align> -> $k {
                %opts{ $k } = $_ with $instruction.config{ $k };
            }
        return %opts if $instruction.name eq 'cell';
        my $contents = recurse-until-str( $instruction );
        my $parsed = $contents ~~ /
            ^ \s*
            [ \: $<option> = ($<name> = ( 'label' | 'header' | 'align' )
                [
                \< ~ \>
                    [ $<args>= ( 'middle' | 'top' | 'left' | 'right' | 'center' | 'centre' | 'top' | 'bottom' )]+ % \s+
                ]? )
            \s* ] +
            $
        /;
        if $parsed {
            for $parsed<option>.list {
                if .<args> {
                    %opts{ .<name>.Str } = ( .<args>>>.Str.list )
                }
                else { %opts{ .<name>.Str } = True }
            }
        }
        %opts
    }
    #| handler for procedural table semantics, table is a 2D semi-infinite grid
    multi method handle(Pod::Block::Named $node where .name ~~ / ^ 'table' $/, Int $in-level,
                        Context $context = None, Bool :$defn = False,  --> Str) {
        #| config for whole table, may include caption, toc, etc.
        my %table-config = $node.config;
        my $level;
        my Bool $toc;
        with %table-config<headlevel> {
            $level = abs($_);
            $toc = $level != 0;
        }
        else {
            with %table-config<toc> {
                $toc = $_;
                $level = 0 unless $toc;
            }
            else {
                $toc = True;
                $level = 1;
            }
        }
        my $target = '';
        my $caption = %table-config<caption> // 'Table';
        $target = $.register-toc(:$level, :text($caption), :$toc);
        my $template = %table-config<template> // 'table';
        my $name-space = %table-config<name-space> // $template;
        my $data = $_ with %!plugin-data{ $name-space };

        # grid traversing algorithm due to Damian Conway
        # Initially empty grid...
        my @grid;
        # How to locate the next empty cell...
        my \find_next_empty = {
            ACROSS => sub (:%at is copy) {
                # Search leftwards for first empty cell...
                repeat { %at<col>++ } until !defined @grid[%at<row>][%at<col>];
                return %at;
            },
            DOWN => sub (:%at is copy) {
                # Search downwards for first empty cell...
                repeat { %at<row>++ } until !defined @grid[%at<row>][%at<col>];
                return %at;
            },
            ROW => sub (:%at is copy) {
                # Search downwards for first row with an empty cell to the right...
                # (Note: starts by searching current row before moving down)
                for %at<row> ..* -> $row {
                    for 0 ..^ %at<col> -> $col {
                        return { :$row, :$col } if !defined @grid[$row][$col];
                    }
                }
            },
            COLUMN => sub (:%at is copy) {
                # Search rightwards for first column with an empty cell above...
                # (Note: starts by searching current column before moving left)
                for %at<col> ..* -> $col {
                    for 0 ..^ %at<row> -> $row {
                        return { :$row, :$col } if !defined @grid[$row][$col];
                    }
                }
            },
        }
        # parse row and column directive contents, should be in node.config
        my %POS = :row(0), :col(0);
        my $DIR = 'ACROSS';
        # Track previous action at each step...
        my $prev-was-cell = False; # because we are in grid
        my @cell-context = ( %(), ); # cell context can be set at grid, row, column, or cell level
        # span type only set at cell level
        for <label header align> -> $k {
            @cell-context[*-1]{ $k } = $_ with %table-config{ $k };
        }
        for $node.contents -> $grid-instruction {
            next if $grid-instruction ~~ Pod::Block::Comment;
            X::ProcessedPod::Table::BadCommand.new( :cmd( $grid-instruction.Str ) ).throw
                unless $grid-instruction.^can('name');
            given $grid-instruction.name {
                when 'cell' {
                    my %payload = %( |@cell-context[*-1], |grid-directive-config( $grid-instruction ) );
                    %payload<data> = trim([~] gather
                        for $grid-instruction.contents { take $.handle($_, $in-level, $context, :$defn) }
                    );
                    my $span;
                    $span = $_ with $grid-instruction.config<span>;
                    with $grid-instruction.config<column-span> {
                        $span[0] = $_;
                        $span[1] //= 1
                    }
                    with $grid-instruction.config<row-span> {
                        $span[0] //= 1;
                        $span[1] = $_
                    }
                    %payload<span> = $span if $span;
                    # Fill current cell with payload...
                    @grid[%POS<row>][%POS<col>] = %payload;
                    # Reserve the full span of cells specified...
                    if $span {
                        for 0 ..^ $span[0] -> $extra-col {
                            for 0 ..^ $span[1] -> $extra-row {
                                @grid[%POS<row> + $extra-row][%POS<col> + $extra-col]
                                        //= %( :no-cell, );
                            }
                        }
                    }
                    # Find next empty cell in the fill direction...
                    %POS = find_next_empty{$DIR}(at => %POS);
                }
                when 'row' {
                    @cell-context.pop if @cell-context.elems > 1;  # this is only false if the first row/column after =table
                    # Check the contents for metadata
                    @cell-context.push: %( |@cell-context[0], |grid-directive-config( $grid-instruction ) );
                    # Start filling across the new row...
                    $DIR = 'ACROSS';
                    # Find the new fill position...
                    if $prev-was-cell {
                        %POS = find_next_empty<ROW>(at => %POS);
                    }
                }
                when 'column' {
                    @cell-context.pop if @cell-context.elems > 1;  # this is only false if the first row/column after =table
                    # Check the contents for metadata
                    @cell-context.push: %( |@cell-context[0], |grid-directive-config( $grid-instruction ) );

                    # Start filling down the new column...
                    $DIR = 'DOWN';
                    # Find the new fill position...
                    if $prev-was-cell {
                        %POS = find_next_empty<COLUMN>(at => %POS);
                    }
                }
                default { # only =cell =row =column allowed after a =grid
                    X::ProcessedPod::Table::BadCommand.new( :cmd( $_ ) ).throw
                }
            }
            # Update previous action...
            $prev-was-cell = $grid-instruction.name eq 'cell';
        };
        $.completion($in-level, $template, %(
            $name-space => $data,
            :config(self.config),
            :@grid,
            :procedural,
            :$target,
            :$caption,
            ), :$defn
        )
    }

    multi method handle(Pod::Defn $node, Int $in-level, Context $context --> Str) {
        $.completion($in-level, 'zero', %(), :defn($!in-defn-list) )
            ~ $.completion($in-level, 'defn',
                %( :term($node.term),
                    %( :contents([~] gather for $node.contents {
                        take self.handle($_, $in-level, :defn, $context)
                    })),
                   $node.config,
                   :config(self.config),
                   :$context,
                ),
                :defn
            )
    }

    multi method handle(Pod::Heading $node, Int $in-level, Context $context, Bool :$defn = False, --> Str) {
        my $retained-list = $.completion($in-level, 'zero', %(), :$defn);
        # process before contents
        my $level = $node.level;
        my $template = $node.config<template> // 'heading';
        my $name-space = $node.config<name-space> // $template;
        my $data = $_ with %!plugin-data{ $name-space };
        my $target = $.register-toc(:$level, :text( recurse-until-str($node).join.trim ), :unique);
        # must register toc before processing content!!
        my $text = trim([~] gather for $node.contents { take $.handle($_, $in-level, Heading, :$defn) });
        $retained-list ~ $.completion($in-level, $template, {
            :$level,
            :$text,
            :$target,
            :top($.pod-file.top),
            $name-space => $data,
            $node.config,
            :config(self.config),
            :$context,
            }, :$defn
        )
    }

    multi method handle(Pod::Item $node, Int $in-level is copy, Context $context, Bool :$defn = False, --> Str) {
        my $level = $node.level - 1;
        while $level < $in-level {
            --$in-level;
            $.itemlist[$in-level] ~= $.rendition('list', %( :items($.itemlist.pop), :config(self.config),))
        }
        while $level >= $in-level {
            $.itemlist[$in-level] = [] unless $.itemlist[$in-level]:exists;
            ++$in-level
        }
        $.itemlist[$in-level - 1].push: $.rendition('item',
                %( :contents([~] gather for $node.contents { take self.handle($_, $in-level, $context) }),
                   $node.config, :config(self.config), :$context, )
                );
        return ''
        # explicitly return an empty string because callers expecting a Str

    }

    multi method handle(Pod::Raw $node, Int $in-level, Context $context = None, Bool :$defn = False, --> Str) {
        $.completion($in-level, 'zero', %(), :$defn )
                ~ $.rendition('raw',
                %( :contents([~] gather for $node.contents { take self.handle($_, $in-level, Context::Raw, :$defn) }),
                   $node.config, :config(self.config), :$context,
                ), :$defn
        )
    }

    multi method handle(Pod::Config $node, Int $in-level, Context $context = None, Bool :$defn = False, --> Str) {
        $.config( $node.type => $node.config, :block-scope );
        $.completion($in-level, 'zero', %(), :$defn )
    }
    multi method handle(Pod::FormattingCode $node where .type ~~ any( <B C I K T U> ), Int $in-level,
                        Context $context = None, Bool :$defn = False,  --> Str) {
        my $contents = [~] gather for $node.contents { take self.handle($_, $in-level, $context, :$defn) };
        my $meta = @($node.meta) // []; # by default an empty array
        $.completion($in-level, 'format-' ~ $node.type.lc ,
                %( :$contents, :$meta, :config(self.config), :$context, ), :$defn
            )
    }
    multi method handle(Pod::FormattingCode $node where .type ~~ none(<E Z X N L P V B C I K T U>), Int $in-level,
                        Context $context = None, Bool :$defn = False,  --> Str) {
        my $contents;
        my $meta = @($node.meta) // []; # by default an empty array
        my $rv;
        # if contents is always a sequence. if it contains embedded PodBlocks,
        # then there will be more than one element.
        if +$node.contents > 1 {
            $rv = FC.parse( $node.contents[*-1]);
            if $rv<metas><meta> {
                $meta.append($rv<metas><meta>».Str);
                $contents = [~] gather for $node.contents[^ (*-1)] { take self.handle($_, $in-level, $context, :$defn) };
                $contents ~= self.handle(~$rv<head>, $in-level, $context, :$defn) if ~$rv<head>;
            }
            else {
                $contents = [~] gather for $node.contents { take self.handle($_, $in-level, $context, :$defn) }
            }
        }
        else {
            $contents = ''; # guarantee at least an empty string
            if $node.contents[0] {
                $rv = FC.parse( $node.contents[0] );
                $meta.append($rv<metas><meta>».Str) if $rv<metas><meta>;
                $contents = self.handle(~$rv<head>, $in-level, $context, :$defn);
            }
        }
        if %.tmpl{ 'format-' ~ $node.type.lc }:exists {
            $.completion($in-level, 'format-' ~ $node.type.lc ,
                %( :$contents, :$meta, :config(self.config), :$context,  ), :$defn
            )
        }
        else {
            $.completion($in-level, 'unknown-name',
                %( :$contents, :$meta, :format-code($node.type), :$context,
                ), :$defn
            )
        }
    }
    # footnotes depends on raw-contents being rendered after rendered contents
    multi method handle(Pod::FormattingCode $node where .type eq 'N', Int $in-level, Context $context = None, Bool :$defn = False, --> Str) {
        my $text = [~] gather for $node.contents { take $.handle($_, $in-level, $context, :$defn) };
        my %params;
        if $context ~~ Context::Raw {
            %params = $!pod-file.raw-footnotes[*-1]
        }
        else {
            %params = $.register-footnote(:$text, :$context )
        }
        $.completion($in-level, 'format-n', %params, :$defn)
    }

    multi method handle(Pod::FormattingCode $node where .type eq 'E', Int $in-level,
                        Context $context = None, Bool :$defn = False,  --> Str) {
        $.completion($in-level, 'raw', %( :contents([~] $node.meta.map({
            when Int { "&#$_;" };
            when Str { "&$_;" };
            $_
        })), :config(self.config), :$context ),  :$defn)
    }

    multi method handle(Pod::FormattingCode $node where .type eq 'Z', Int $in-level, $context = None, Bool :$defn = False,  --> Str) {
        $.completion($in-level, 'zero',
                %( :contents([~] gather for $node.contents { take self.handle($_, $in-level, $context, :$defn) }),
                 :config(self.config), :$context,
                ), :$defn)
    }

    multi method handle(Pod::FormattingCode $node where .type eq 'X', Int $in-level,
                        Context $context = None, Bool :$defn = False,  --> Str) {
        my Bool $header = $context ~~ Heading;
        my $text = [~] gather for $node.contents { take $.handle($_, $in-level, $context, :$defn) };
        return ' ' unless $text or +$node.meta;
        # ignore if there is nothing that can be an entry
        my $target = $.register-glossary($text, $node.meta, $header);
        #s/recurse-until-str($node).join /$text/
        $.completion($in-level, 'format-x', %( :$text, :$target, :$header, :$context,  :meta($node.meta):config(self.config),), :$defn)
    }

    multi method handle(Pod::FormattingCode $node where .type eq 'L', Int $in-level,
                        Context $context = None, Bool :$defn = False,  --> Str) {
        my $contents = [~] gather for $node.contents { take $.handle($_, $in-level, $context) };
        my ($target, $type, $place, $link-label) = $.register-link($node.meta eqv [] | [""] ?? $contents !! $node.meta[0], $contents);
        # link handling needed here to deal with local links in global-link context
        $.completion($in-level, 'format-l',
            %( :$target,
               :$link-label,
               :$type,
               :$place,
               :config(self.config),
               :meta( $node.meta ),
               :$context,
            ), :$defn
        )
    }

    multi method handle(Pod::FormattingCode $node where .type eq 'V', Int $in-level,
                        Context $context = None, Bool :$defn = False, --> Str) {
        $.completion($in-level, 'escaped',
            %( :contents([~] gather for $node.contents { take self.handle($_, $in-level, $context, :$defn) }),
             :config(self.config), :$context,
            ), :$defn
        )
    }

    multi method handle(Pod::FormattingCode $node where .type eq 'P', Int $in-level,
                        Context $context = None, Bool :$defn = False, --> Str) {
        my Str $link-contents = recurse-until-str($node);
        my $link = ($node.meta eqv [] | [""] ?? $link-contents !! $node.meta).Str.trim;
        my $schema = '';
        my $uri = '';
        if $link ~~ / ^ $<sch> = (\w+) ':' \s* $<uri> = (.*) $ / {
            $schema = $<sch>.Str;
            $uri = $<uri>.Str
        }
        my Str $contents;
        my Bool $as-pre = True;
        my Bool $html = False;
        my $target;
        given $schema {
            when 'toc' {
                $contents = "See: $link-contents"
            }
            when 'index' {
                $contents = "See: $link-contents"
            }
            when 'semantic' {
                $as-pre = False;
                my $caption;
                my $level;
                $.pod-file.raw-metadata
                        .grep({ .<name> ~~ $uri })
                        .map({
                            $contents ~= .<value> ;
                            $caption = .<caption> without $caption;
                            $level = .<level> without $level;
                        });
                without $contents {
                    $contents = "See: $link-contents";
                    $as-pre = True;
                }
                $caption = $uri without $caption;
                $level = 1 without $level;
                $target = $.register-toc(:$level, :text($caption), :toc, :unique );
            }
            when 'http' | 'https' {
                my LibCurl::Easy $curl;
                $curl .= new(:URL($link), :followlocation, :failonerror );
                try {
                    $curl.perform;
                    $contents = $curl.perform.content;
                    CATCH {
                        when X::LibCurl {
                            $contents = "Link ｢$link｣ caused LibCurl Exception, response code ｢{ $curl.response-code }｣ with error ｢{ $curl.error }｣"
                            }
                        default {
                            $contents = "Link ｢$link｣ caused LibCurl Exception, response code ｢{ $curl.response-code }｣ with error ｢{ $curl.error }｣"
                        }
                    }
                }
            }
            when 'file' | '' {
                my URI $uri .= new($link);
                if $uri.path.Str.IO ~~ :e & :f {
                    $contents = $uri.path.Str.IO.slurp;
                }
                else {
                    $contents = "See: $link-contents";
                    note "No file found at ｢$link｣" if $.debug;
                }
            }
            default {
                $contents = "See: $link-contents"
            }
        }
        $html = so $contents ~~ / '<html' .+ '</html>'/;
        $contents = ~$/ if $html;
        # eliminate any chars outside the <html> container if there is one
        $.completion($in-level, 'format-p', %(
            :$contents,
            :$html,
            :config(self.config),
            :meta( $node.meta ),
            :$context,
            :$as-pre,
            :$target,
        ), :$defn)
    }
}