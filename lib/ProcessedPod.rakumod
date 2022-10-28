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
    # Variable relating to a specific pod file

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
    #| information to be included in eg html header
    has @.raw-metadata;
    #| toc structure , collected and rendered separately to body
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
    multi method gist(PodFile:U: ) { 'Undefined PodFile' }
    multi method gist(PodFile:D: ) {
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

    my enum Context <None Heading HTML Raw Output InPodCode>;

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
    method rewrite-target(Str $candidate-name is copy, :$unique --> Str) {
        # target names inside the POD file, eg., headers, glossary, footnotes
        # function is called to canonise the target name and to ensure - if necessary - that
        # the target name used in the link is unique.
        # This method uses the default algorithm for HTML and POD
        # It may need to be over-ridden, eg., for MarkDown which uses a different targeting function.

        return DEFAULT_TOP if $candidate-name eq DEFAULT_TOP;
        # don't rewrite the top

        $candidate-name = $candidate-name.subst(/\s+/, '_', :g);
        if $unique {
            $candidate-name ~= '_0' if $candidate-name (<) $!pod-file.targets;
            ++$candidate-name while $!pod-file.targets{$candidate-name};
            # will continue to loop until a unique name is found
        }
        $!pod-file.targets{$candidate-name}++;
        # now add to targets, no effect if not unique
        $candidate-name
    }

    # Methods relating to customisation
    method add-plugin(Str $plugin-name,
                      :$path = $plugin-name,
                      :$template-raku = "templates.raku",
                      :$custom-raku = "blocks.raku",
                      :%config is copy
                      ) {
        X::ProcessedPod::NamespaceConflict.new(:name-space($plugin-name)).throw
            if %!plugin-data{$plugin-name}:exists;
        with %config {
            %config<path> = $path
        }
        else {
            %config = %( :$path )
        }
        self.modify-templates( $template-raku, :$path, :plugin ) if $template-raku;
        self.add-custom( $custom-raku, :$path ) if $custom-raku;
        self.add-data( $plugin-name, %config )
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
    method add-data($name-space, $data-object ) {
        return unless $data-object;
        X::ProcessedPod::NamespaceConflict.new(:$name-space).throw
                if %!plugin-data{$name-space}:exists;
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
        $!pod-file .= new;

        #clean out the variables, whilst keeping the Templating engine cache.
        $!metadata = $!toc = $!glossary = $!footnotes = $!body = Nil;
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
            :name($!pod-file.name),
            :title($!pod-file.title),
            :title-target($!pod-file.title-target),
            :subtitle($!pod-file.subtitle),
            :page-config($!pod-file.pod-config-data),
            :$!metadata,
            :lang($!pod-file.lang),
            :$!toc,
            :$!glossary,
            :$!footnotes,
            :$!body,
            :path($!pod-file.path),
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
        self.rendition('toc', %( :toc([@filtered])));
    }

    #| renders only the glossary
    method render-glossary(-->Str) {
        return '' if (!?$!pod-file.raw-glossary.keys or $.no-glossary or $.pod-file.pod-config-data<no-glossary>);
        #No render without any keys
        my @filtered = [gather for $!pod-file.raw-glossary.sort { take %(:text(.key), :refs([.value.sort])) }];
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
        self.rendition('meta', %( :meta($!pod-file.raw-metadata)))
    }

    # methods to collect page component data

    #| registers a header or title in the toc structure
    #| is-title is true for TITLE and SUBTITLE blocks, false otherwise
    method register-toc(:$level!, :$text!, Bool :$is-title = False --> Str) {
        my $target = self.rewrite-target($text, :unique($is-title));
        # if a title (TITLE) then it must be unique
        $!pod-file.raw-toc.push: %( :$level, :$text, :$target, :$is-title );
        $target
    }

    method register-glossary(Str $text, @entries, Bool $is-header --> Str) {
        my $target;
        # The following was written so that titles would only have one ingoing link
        # But legacy P2HTML requires two, one for the glossary, one for the toc.
        # So checking the TOC is not needed.
        #        if $is-header
        #        {
        #            if +@.pod-file.raw-toc
        #            {
        #                $target = @.pod-file.raw-toc[*- 1]<target>
        #                # the last header to be added to the toc will have the url we want
        #            }
        #            else
        #            {
        #                $target = $!pod-file.front-matter
        #                # if toc not initiated, then before 1st header
        #            }
        #        }
        #        else
        #        {
        # there must be something in either text or entries[0] to get here
        # the following target function is so complex solely in order to match
        # the requirements of legacy P2HTML
        $target = ('index-entry'
                ~ (@entries ?? '-' !! '') ~ @entries.join('-')
                ~ ($text ?? '-' !! '') ~ $text
        ).subst('_', '__', :g).subst(' ', '_', :g);
        $target = self.rewrite-target($target, :unique);
        #        } #from else
        # Place information is needed when a glossary is constructed without a return anchor reference,
        # so the most recent header is used
        my $place = +$.pod-file.raw-toc ?? $.pod-file.raw-toc[*- 1]<text> !! $!pod-file.front-matter;
        if @entries {
            for @entries {
                $.pod-file.raw-glossary{.[0]} = Array unless $.pod-file.raw-glossary{.[0]}:exists;
                if .elems > 1 { $.pod-file.raw-glossary{.[0]}.push: %(:$target, :place(.[1])) }
                else { $.pod-file.raw-glossary{.[0]}.push: %(:$target, :$place) }
            }
        }
        else {
            # if no entries, then there must be $text to get here
            $.pod-file.raw-glossary{$text} = Array unless $.pod-file.raw-glossary{$text}:exists;
            $.pod-file.raw-glossary{$text}.push: %(:$target, :$place);
        }
        $target
    }

    method register-link(Str $entry, Str $link-label --> Positional ) {
        return $.pod-file.links{$entry}<target link-label type place> if $.pod-file.links{$entry}:exists;
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
        $.pod-file.links{$entry}<target link-label type place>
    }

    # A footnote structure is created storing both the target anchor (with the footnote text)
    # and the return anchor (with the text from which the footnote originates, to be used in the footnote
    # to return the cursor if desired).

    method register-footnote(:$text! --> Hash) {
        my $fnNumber = +$!pod-file.raw-footnotes + 1;
        my $fnTarget = self.rewrite-target("fn$fnNumber", :unique);
        my $retTarget = self.rewrite-target("fnret$fnNumber", :unique);
        $!pod-file.raw-footnotes.push: %( :$text, :$retTarget, :$fnNumber, :$fnTarget);
        (:$fnTarget, :$fnNumber, :$retTarget).hash
    }

    # Pod specifies Meta data for use in an HTML header context, but it could be used in other
    # contexts, such as epub or pdf for the author, version, etc.

    method register-meta(:$name, :$value) {
        $!pod-file.raw-metadata.push: %( :$name, :$value)
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
        {*}
    }

    #| Handle processes Pod blocks, bare strings, and throws if a Nil
    multi method handle(Nil) {
        X::ProcessedPod::Unexpected-Nil.new.throw
    }
    #| handle strings within a Block, don't need to be escaped if HTML
    multi method handle(Str $node, Int $in-level, Context $context --> Str) {
        $.rendition((($context ~~ HTML | Raw ) or ( $context ~~ InPodCode and $.no-code-escape)) ?? 'raw' !! 'escaped', %( :contents(~$node)))
    }

    multi method handle(Pod::Block::Code $node, Int $in-level, Context $context = InPodCode, Bool :$defn = False,  --> Str) {
        # first completion is to flush a retained list before the contents of the block are processed
        my $retained-list = $.completion($in-level, 'zero', %(), :$defn );
        my $contents = [~] gather for $node.contents { take self.handle($_, $in-level, InPodCode, :$defn ) };
        $retained-list ~ $.completion($in-level, 'block-code', %( :$contents ), :$defn );
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
        $.completion($in-level, 'zero', %(), :$defn )
            ~ $.completion($in-level, $template, %(
                :name($node.name),
                :$target,
                :1level,
                :contents([~] gather for $node.contents { take self.handle($_, $in-level, $context, :$defn ) }),
                :top($.pod-file.top),
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
            $.pod-block-processed = True;
            note "Processing first pod declaration in file { $.pod-file.path }" if $.debug;
        }
        my $template = $node.config<template> // 'pod';
        $.completion($in-level, $template, %(
            :$name,
            :contents([~] gather for $node.contents { take self.handle($_, $in-level, $context, :$defn) }),
            :tail($.completion( 0, 'zero', %(), :$defn ))
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

    multi method handle(Pod::Block::Named $node where .name ~~ any(<VERSION DESCRIPTION AUTHOR SUMMARY>),
                        Int $in-level, Context $context, Bool :$defn = False, --> Str) {
        $.register-meta(:name($node.name.tclc), :value(recurse-until-str($node)));
        $.completion($in-level, 'zero', %(), :$defn )
        # make sure any list is correctly ended.
    }

    multi method handle(Pod::Block::Named $node where $node.name.lc eq 'html' , Int $in-level,
                        Context $context = None, Bool :$defn = False, --> Str) {
        $.completion($in-level, 'zero', %(), :$defn )
            ~ $.completion($in-level, 'raw', %( :contents([~] gather for $node.contents { take self.handle($_,
                $in-level, HTML, :$defn) }), $node.config
            ), :$defn
        )
    }

    multi method handle(Pod::Block::Named $node where .name.lc eq 'output', Int $in-level,
                        Context $context = None, Bool :$defn = False,  --> Str) {
        $.completion($in-level, 'zero', %(), :$defn )
            ~ $.completion($in-level, 'output',
            %( :contents([~] gather for $node.contents { take self.handle($_, $in-level, Output, :$defn) }),$node.config
            ), :$defn
        )
    }

    multi method handle(Pod::Block::Named $node where .name.lc eq 'raw', Int $in-level,
                        Context $context = None, Bool :$defn = False,  --> Str) {
        $.completion($in-level, 'zero', %(), :$defn )
            ~ $.completion($in-level, 'raw',
            %( :contents([~] gather for $node.contents { take self.handle($_, $in-level, $context, :$defn) }),$node.config)
            , :$defn
        )
    }

    multi method handle(Pod::Block::Named $node where .name ~~ any(@.custom), Int $in-level,
                        Context $context = None, Bool :$defn = False,  --> Str) {
        my $level = abs($node.config<headlevel> // 1); # no negative levels
        my $target = '';
        $target = $.register-toc(:$level, :text(recurse-until-str($node).tclc))
            if +$level;
        my $template = $node.config<template> // $node.name.lc;
        my $data;
        my $name-space = $node.config<name-space> // $template // $node.name.lc;
        $data = $_ with %!plugin-data{ $name-space };
        $.completion($in-level, 'zero', %(), :$defn )
            ~ $.completion($in-level, $template,
            %( :contents([~] gather for $node.contents { take self.handle($_, $in-level, $context, :$defn) }),
            $node.config,
            :$target,
            :raw-contents( [~] gather for $node.contents { take self.handle($_, $in-level, Raw, :$defn ) } ),
            "$name-space" => $data
            ), :$defn
        )
    }

    multi method handle(Pod::Block::Para $node, Int $in-level, Context $context where *== Output, Bool :$defn = False, --> Str) {
        $.completion($in-level, 'zero', %(), :$defn )
                ~ $.completion($in-level, 'raw',
            %( :contents([~] gather for $node.contents { take self.handle($_, $in-level, $context, :$defn) }),$node.config)
                , :$defn)

    }

    multi method handle(Pod::Block::Para $node, Int $in-level, Context $context, Bool :$defn = False,  --> Str) {
        note "Defn flag is $defn and context is $context" if $.verbose;
        $.completion($in-level, 'zero', %(), :$defn )
            ~ $.completion($in-level, ($defn || $context !~~ None ) ?? 'raw' !! 'para' ,
            %( :contents([~] gather for $node.contents { take self.handle($_, $in-level, $context) }),$node.config)
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
                }])
                ,$node.config
                ), :$defn
            )
    }

    multi method handle(Pod::Defn $node, Int $in-level, Context $context --> Str) {
        $.completion($in-level, 'zero', %(), :defn($!in-defn-list) )
            ~ $.completion($in-level, 'defn',
                %( :term($node.term), %( :contents([~] gather for $node.contents { take self.handle($_,
                $in-level, :defn, $context) })),$node.config
                ),
                :defn
            )
    }

    multi method handle(Pod::Heading $node, Int $in-level, Context $context, Bool :$defn = False, --> Str) {
        my $retained-list = $.completion($in-level, 'zero', %(), :$defn);
        # process before contents
        my $level = $node.level;
        my $template = $node.config<template> // 'heading';
        my $target = $.register-toc(:$level, :text(recurse-until-str($node).join.trim));
        # must register toc before processing content!!
        my $text = trim([~] gather for $node.contents { take $.handle($_, $in-level, Heading, :$defn) });
        $retained-list ~ $.completion($in-level, $template, {
            :$level,
            :$text,
            :$target,
            :top($.pod-file.top),
            $node.config
            }, :$defn
        )
    }

    multi method handle(Pod::Item $node, Int $in-level is copy, Context $context, Bool :$defn = False, --> Str) {
        my $level = $node.level - 1;
        while $level < $in-level {
            --$in-level;
            $.itemlist[$in-level] ~= $.rendition('list', %( :items($.itemlist.pop)))
        }
        while $level >= $in-level {
            $.itemlist[$in-level] = [] unless $.itemlist[$in-level]:exists;
            ++$in-level
        }
        $.itemlist[$in-level - 1].push: $.rendition('item',
                %( :contents([~] gather for $node.contents { take self.handle($_, $in-level, $context) }),$node.config)
                );
        return ''
        # explicitly return an empty string because callers expecting a Str

    }

    multi method handle(Pod::Raw $node, Int $in-level, Context $context = None, Bool :$defn = False, --> Str) {
        $.completion($in-level, 'zero', %(), :$defn )
                ~ $.rendition('raw',
                %( :contents([~] gather for $node.contents { take self.handle($_, $in-level, Context::Raw, :$defn) }),
                   $node.config
                ), :$defn
        )
    }

    multi method handle(Pod::Config $node, Int $in-level, Context $context = None, Bool :$defn = False, --> Str) {
        $.completion($in-level, 'zero', %(), :$defn )
            ~ $.completion($in-level, 'comment',
            %( :contents($node.type ~ '=' ~ $node.config.raku)))
    }
    multi method handle(Pod::FormattingCode $node where .type ~~ any( <B C I K T U> ), Int $in-level,
                        Context $context = None, Bool :$defn = False,  --> Str) {
        my $contents = [~] gather for $node.contents { take self.handle($_, $in-level, $context, :$defn) };
        my $meta = @($node.meta) // []; # by default an empty array
        $.completion($in-level, 'format-' ~ $node.type.lc ,
                %( :$contents, :$meta ), :$defn
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
            $rv = FC.parse( $node.contents[0]);
            $meta.append($rv<metas><meta>».Str) if $rv<metas><meta>;
            $contents = self.handle(~$rv<head>, $in-level, $context, :$defn);
        }
        if %.tmpl{ 'format-' ~ $node.type.lc }:exists {
            $.completion($in-level, 'format-' ~ $node.type.lc ,
                %( :$contents, :$meta ), :$defn
            )
        }
        else {
            $.completion($in-level, 'escaped',
                %( :contents($node.type ~ '<'
                    ~ $contents.Str
                    ~ ($meta ?? '|' ~ $meta>>.Str !! '')
                    ~ '>')
                ), :$defn
            )
        }
    }

    multi method handle(Pod::FormattingCode $node where .type eq 'N', Int $in-level, Context $context = None, Bool :$defn = False, --> Str) {
        my $text = [~] gather for $node.contents { take $.handle($_, $in-level, $context, :$defn) };
        $.completion($in-level, 'format-n', $.register-footnote(:$text), :$defn)
    }

    multi method handle(Pod::FormattingCode $node where .type eq 'E', Int $in-level,
                        Context $context = None, Bool :$defn = False,  --> Str) {
        $.completion($in-level, 'raw', %( :contents([~] $node.meta.map({
            when Int { "&#$_;" };
            when Str { "&$_;" };
            $_
        }))), :$defn)
    }

    multi method handle(Pod::FormattingCode $node where .type eq 'Z', Int $in-level, $context = None, Bool :$defn = False,  --> Str) {
        $.completion($in-level, 'zero',
                %( :contents([~] gather for $node.contents { take self.handle($_, $in-level, $context, :$defn) })
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
        $.completion($in-level, 'format-x', %( :$text, :$target, :$header), :$defn)
    }

    multi method handle(Pod::FormattingCode $node where .type eq 'L', Int $in-level,
                        Context $context = None, Bool :$defn = False,  --> Str) {
        my $contents = [~] gather for $node.contents { take $.handle($_, $in-level, $context) };
        my ($target, $link-label, $type, $place) = $.register-link($node.meta eqv [] | [""] ?? $contents !! $node.meta[0], $contents);
        # link handling needed here to deal with local links in global-link context
        $.completion($in-level, 'format-l',
            %( :$target,
               :$link-label,
               :local( $type eq 'local' ),
               :internal( $type eq 'internal' ),
               :external( $type eq 'external' ),
               :$place
            ), :$defn
        )
    }

    multi method handle(Pod::FormattingCode $node where .type eq 'V', Int $in-level,
                        Context $context = None, Bool :$defn = False, --> Str) {
        $.completion($in-level, 'escaped',
            %( :contents([~] gather for $node.contents { take self.handle($_, $in-level, $context, :$defn) })
            ), :$defn
        )
    }

    multi method handle(Pod::FormattingCode $node where .type eq 'P', Int $in-level,
                        Context $context = None, Bool :$defn = False, --> Str) {
        my Str $link-contents = recurse-until-str($node);
        my $link = ($node.meta eqv [] | [""] ?? $link-contents !! $node.meta).Str;
        my URI $uri .= new($link);
        my Str $contents;
        my LibCurl::Easy $curl;
        my Bool $html = False;
        given $uri.scheme {
            when 'http' | 'https' {
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
                if $uri.path.Str.IO.f {
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
        $.completion($in-level, 'format-p', %( :$contents, :$html), :$defn)
    }
}