use v6.d;
use Template::Mustache;
use ProcessedPod::Exceptions;

use URI;
use LibCurl::Easy;
use trace;
unit class ProcessedPod;
    class Pseudo { has $.contents }; # required for the highlighter
    # template related variables independently of the templating system
    has %.tmpl;
    has @!required = < raw comment escaped glossary footnotes
            format-c block-code format-u para format-b named source-wrap defn output format-l
            format-x heading title format-n format-i format-k format-p meta list subtitle format-r
            format-t table item notimplemented section toc pod >;
    has $.engine; # slot for template engine. Should only be set in first call to rendition, or after call to replace-template

    # defaults
    has $.default-top = '___top'; # the name of the anchor at the top of a source file

    # provided at instantiation or by attributes on Class instance
    has $.front-matter is rw = 'preface'; # Text between =TITLE and first header, this is used to refer for textual placenames
    has Str $.name is rw;
    has Str $.title is rw = $!name;
    has Str $.subtitle is rw = '';
    has Str $.path is rw; # should be path of original document, defaults to $.name
    has Str $.top is rw = $!default-top; # defaults to top, then becomes target for TITLE
    has &.highlighter is rw; # a callable (eg. provided by external program) that converts [html] to highlighted raku code
    # highlighter is expected to be a callback, a sub expecting :node, which should have a method .contents, and :default
    # which uses the value of node.contents to generate a string.

    # Output rendering information
    has Bool $.no-meta is rw = False; # set to True eliminates meta data rendering
    has Bool $.no-footnotes is rw = False; # set to True eliminates rendering of footnotes
    has Bool $.no-toc is rw = False; # set to True to exclude TOC even if there are headers
    has Bool $.no-glossary is rw = False; # set to True to exclude Glossary even if there are internal anchors

    # debugging
    has Bool $.debug is rw; # outputs to STDERR information on processing
    has Bool $.verbose is rw; # outputs to STDERR more detail about errors.

    # populated by process-pod method
    has Str $.pod-body is rw; # single process call
    has Str $.body is rw = ''; # concatenation of multiple process calls
    has @.metadata; # information to be included in eg html header
    has Str $!metadata; # metadata when rendered
    has @.toc; # toc structure , collected and rendered separately to body
    has Str $!toc; # rendered toc
    has %.glossary; # glossary structure
    has Str $!glossary; # rendered glossary
    has @.footnotes; # footnotes structure
    has Str $!footnotes; # rendered footnotes
    has Str $.renderedtime; # when source wrap is called

    # A set of counters for Headers
    has Int @.counters is default(0);
    has Str $.counter-separator is rw = '.';
    has Bool $.no-counters is rw = False;

    # variables to manage Pod state, where rendering is dependent on local context
    has @.itemlist; # for multilevel lists
    has Bool $!in-defn-list = False; # used to register state when processing a definition list

    submethod BUILD  (
        :$!name = 'UNNAMED',
        :$templates,
        :$!title = $!name,
        :$!debug = False,
        :$!verbose = False,
        :$!path = $!name,
        :&!highlighter,
        ) {
        given $templates {
            when Hash { %!tmpl = $templates }
            when Str {
                #use SEE_NO_EVAL;
                %!tmpl = EVALFILE $templates ;
            } # a string is a filename with a compilable file
        }
        CATCH {
            default {
                X::ProcessedPod::TemplateFailure.new( :error( .message ) ).throw
            }
        }
    }

    submethod TWEAK {
        X::ProcessedPod::MissingTemplates.new(:missing( ( @!required (-) %!tmpl.keys ).keys.flat )).throw
            unless %!tmpl.keys (>=) @!required;
                    # the keys on the RHS above are required in %.tmpl. To throw here, the templates supplied are not
                    # a superset of the required keys.
        $!top = self.rewrite-target( $!default-top , :unique);
        with %*ENV<PODRENDER> {
            $!no-toc = ?m/:i 'No' \-? 'TOC'/;
            $!no-footnotes = ?m/:i 'No' \-? 'Foot'/;
            $!no-glossary = ?m/:i 'No' \-? 'Glos'/;
            $!no-meta = ?m/:i 'No' \-? 'Meta'/;
        }
        note "Debug is ON" if $!debug;
    }

    =comment rendition() is the only method that needs to be over-ridden for a different template system.

    #| maps the key to template and renders the block
    method rendition(Str $key, %params --> Str) {
        $!engine = Template::Mustache.new without $!engine;
        return '' if $key eq 'zero';
        # special case this as there must be no EOL.
        X::ProcessedPod::Non-Existent-Template.new( :$key ).throw
                unless %!tmpl{$key}:exists;
        # templating engines like mustache do not handle logic or loops, which some Pod formats require.
        # hence we pass a Subroutine instead of a string in the template
        # the subroutine takes the same parameters as rendition and produces a mustache string
        # eg P format template escapes containers

        note "At $?LINE rendering with \<$key>" if $.debug;
        $!engine.render(
                %!tmpl{ $key } ~~ Block ??
                %!tmpl{$key}(  %params ) # if the template is a block, then run as sub and pass in the params
                !! %!tmpl{$key}
                , %params , :literal
                )
    }

    #| allows for templates to be replaced during pod processing
    method replace-template( %new-templates )
    {
        { %!tmpl{ $^a } = $^b } for %new-templates.kv;
        $!engine = Nil; # This will force a reinstantiation of the template engine.
        # a new instance is not made here because using a new template engine would require two functions to be overidden
    }

    =comment The next function is placed here because it may need to be over-ridden. (see Pod::To::Markdown)

    #| rewrites targets (link destinations) to be made unique and to be cannonised depending on the output format
    #| takes the candidate name and whether it should be unique, returns with the cannonised link name
    method rewrite-target(Str $candidate-name is copy, :$unique --> Str ) {
        state SetHash $targets .= new;
        # target names inside the POD file, eg., headers, glossary, footnotes
        # function is called to cannonise the target name and to ensure - if necessary - that
        # the target name used in the link is unique.
        # This method uses the default algorithm for HTML and POD
        # It may need to be over-ridden, eg., for MarkDown which uses a different targetting function.

        # when indexing a unique target is needed even when same entry is repeated
        # when a Heading is a target, the reference must come from the name
        # the algorithm for target names comes from github markup
        # https://gist.github.com/asabaylus/3071099#gistcomment-2563127
        # because it matters for MarkDown but not for html
#        function GithubId(val) {
#	return val.toLowerCase().replace(/ /g,'-')
#		// single chars that are removed
#		.replace(/[`~!@#$%^&*()+=<>?,./:;"'|{}\[\]\\–—]/g, '')
#		// CJK punctuations that are removed
#		.replace(/[　。？！，、；：“”【】（）〔〕［］﹃﹄“”‘’﹁﹂—…－～《》〈〉「」]/g, '')
#}
        return $!default-top if $candidate-name eq $!default-top; # don't rewrite the top
        $candidate-name = $candidate-name.subst(/\s+/,'_',:g);
        if $unique {
            $candidate-name ~= '_0' if $candidate-name (<) $targets;
            ++$candidate-name while $targets{$candidate-name}; # will continue to loop until a unique name is found
        }
        $targets{ $candidate-name }++; # now add to targets, no effect if not unique
        $candidate-name
    }

    =comment process-pod is called to populate the processed variables.

    #| process the pod block or tree passed to it, and concatenates it to previous pod tree
    #| returns a string representation of the tree in the required format
    method process-pod( $pod --> Str ) {
        $!pod-body = [~] $pod>>.&handle( 0, self );
        $!body ~= $!pod-body # returns accumulated pod-bodies
    }

    =comment methods to provide output from a processed pod

    #| renders a pod tree, but probably a block
    #| returns only the pod that was passed
    method render-block( $pod --> Str ) {
        self.process-pod( $pod );
        $!pod-body # returns only most recent pod-body
    }

    #| renders the whole pod tree
    #| is actually an alias to process-pod
    method render-tree( $pod --> Str ) { # an alias for a consistent naming system
        self.process-pod( $pod );
    }

    =comment generating the template engine is expensive if only generating small sections of pod.

    #| deletes any previously processed pod, keeping the template engine cache
    method delete-pod-structure( --> Hash ) {
        self.render-structures without $!renderedtime;
        my %h =
                :$!name,
                :$!title,
                :$!subtitle,
                :$!metadata,
                :$!toc,
                :$!glossary,
                :$!footnotes,
                :$!body,
                :$!path,
                :$!renderedtime,
                :raw-metadata(@!metadata.clone),
                :raw-toc(@!toc.clone),
                :raw-glossary(%!glossary.clone),
                :raw-footnotes(@!footnotes.clone)
                ;
        #clean out the variables, whilst keeping the Templating engine cache.
        $!name = $!title = $!subtitle = $!metadata = $!toc
                = $!glossary = $!footnotes = $!body = $!path = $!renderedtime = Nil;
        @!metadata = @!toc = @!footnotes = ();
        %!glossary = Empty;
        %h
    }

    =comment These are the rendering functions for the file and the file structures.
    The first pass creates the rendering for a pod tree, and collects data for TOC/glossary/footnotes
    Then the structures are rendered after the body has been prepared.

    #| saves the rendered pod tree as a file, and its document structures, uses source wrap
    #| filename defaults to the name of the pod tree, and ext defaults to html
    method file-wrap(:$filename = $.name, :$ext = 'html' ) {
        "$filename\.$ext".IO.spurt: self.source-wrap
    }

    #| renders all of the document structures, and wraps them and the body
    #| uses the source-wrap template
    method source-wrap( --> Str ) {
        self.render-structures without $!renderedtime;
        self.rendition('source-wrap', {
            :$!name,
            :$!title,
            :$!subtitle,
            :$!metadata,
            :$!toc,
            :$!glossary,
            :$!footnotes,
            :$!body,
            :$!path,
            :$!renderedtime
        } )
    }

    method render-structures {
        without $!renderedtime
        {
            $!metadata = self.render-meta;
            $!toc = self.render-toc;
            $!glossary = self.render-glossary;
            $!footnotes = self.render-footnotes;
            $!renderedtime = now.DateTime.utc.truncated-to('seconds').Str ;
        }
    }

    #| renders only the toc
    method render-toc( --> Str ) {
        # if no headers in pod, then no need to include a TOC
        return '' if ( ! ?@!toc or $.no-toc);
        my @filtered = @!toc.grep( { !( .<is-title>) } );
        @filtered.map({ .<counter>.subst-mutate(/\./,$.counter-separator,:g) }) if $.counter-separator ne '.';
        @filtered.map({ .<counter>:delete}) if $.no-counters;
        self.rendition('toc', %( :toc( [ @filtered ] )  ));
    }

    #| renders only the glossary
    method render-glossary(-->Str) {
        return '' if ( ! ?%!glossary.keys or $.no-glossary); #No render without any keys
        my @filtered = [gather for %!glossary.sort {  take %(:text(.key), :refs( [.value.sort] )) } ];
        self.rendition( 'glossary', %( :glossary( @filtered )  )  )
    }

    #| renders only the footnotes
    method render-footnotes(--> Str){
        return '' if ( ! ?@!footnotes or $!no-footnotes ); # no rendering of code if no footnotes
        self.rendition('footnotes', %( :notes( @!footnotes )  ) )
    }

    #| renders on the meta data
    method render-meta(--> Str) {
        return '' if ( ! ?@!metadata or $!no-meta );
        self.rendition('meta', %( :meta( @!metadata )  ))
    }

    =comment methods to collect structure data

    #| registers a header or title in the toc structure
    #| is-title is true for TITLE and SUBTITLE blocks, false otherwise
    method register-toc(:$level!, :$text!, Bool :$is-title = False --> Str) {
        my $counter = '';
        unless $is-title or $.no-counters {
            @!counters[$level - 1]++;
            @!counters.splice($level);
            $counter = @!counters>>.Str.join: $.counter-separator;
        }
        my $target = self.rewrite-target($text, :!unique ) ;
        @!toc.push: %( :$level, :$text, :$target, :$is-title, :$counter );
        $target
    }

    method register-glossary(Str $text, @entries, Bool $is-header --> Str) {
        my $target;
        if $is-header
        {
            if +@.toc
            {
                $target = @.toc[ * - 1 ]<target>
                # the last header to be added to the toc will have the url we want
            }
            else
            {
                $target = $!front-matter
                # if toc not initiated, then before 1st header
            }
        }
        else
        {
            # there must be something in either text or entries[0] to get here
            $target = @entries ?? @entries.join('-') !! $text;
            $target = self.rewrite-target($target, :unique)
        }
        # Place information is needed when a glossary is constructed without a return anchor reference,
        # so the most recent header is used
        my $place = +@.toc ?? @.toc[ * - 1]<text> !! $!front-matter;
        if @entries {
            for @entries {
                %.glossary{ .[0] } = Array unless %.glossary{ .[0] }:exists;
                if .elems > 1 { %.glossary{ .[0] }.push: %(:$target, :place( .[1] )) }
                else { %.glossary{ .[0] }.push: %(:$target, :$place ) }
            }
        }
        else { # if no entries, then there must be $text to get here
            %.glossary{$text} = Array unless %.glossary{$text}:exists;
            %.glossary{$text}.push: %(:$target, :$place);
        }
        $target
    }

    =comment This method could be over-ridden in order to collect the links inside a pod, eg., for error checking

    method register-link(Str $entry, Str $target --> Str) {
        # A link may be
        # - internal to the document (in which case it needs to be rewritten to conform)
        # - to a group of documents with the same format (rewritten to conform)
        # - to an external source, assuming only http type links (not rewritten)
        if $target ~~ / ^ 'http://' | ^ 'https://' /
        { $target }
        else
        { self.rewrite-target($target, :!unique); }
    }

    =comment A footnote structure is created storing both the target anchor (with the footnote text)
    and the return anchor (with the text from which the footnote originates, to be used in the footnote
    to return the cursor if desired).

    method register-footnote(:$text! --> Hash ) {
        my $fnNumber = +@!footnotes + 1;
        my $fnTarget = self.rewrite-target("fn$fnNumber",:unique) ;
        my $retTarget = self.rewrite-target("fnret$fnNumber",:unique);
        @!footnotes.push: %( :$text, :$retTarget, :$fnNumber, :$fnTarget  );
        (:$fnTarget, :$fnNumber, :$retTarget).hash
    }

    =comment Pod specifies Meta data for use in an HTML header context, but it could be used in other
    contexts, such as epub or pdf for the author, version, etc.

    method register-meta( :$name, :$value ) {
        @!metadata.push: %( :$name, :$value )
    }

    =comment This is the routine called at the end of a Pod block and is used to determine whether the cursor
    is in the context of a B<List> or B<Definition>, which may be recursively called.

    #| verifies whether a list has completed, otherwise adding items or definitions to the list
    #| completes list if the context indicates the end of a list
    #| returns the string representation of the block / list
    method completion(Int $in-level, Str $key, %params --> Str) {
        my Str $rv = '';
        # first deal with any existing defn list when next not a defn
        my $top-level = @.itemlist.elems;
        while $top-level > $in-level {
            if $top-level > 1 {
                @.itemlist[$top-level - 2][0] = '' unless @.itemlist[$top-level - 2][0]:exists;
                @.itemlist[$top-level - 2][* - 1] ~= self.rendition('list', %( :items( @.itemlist.pop )  ));
                note "At $?LINE rendering with template ｢list｣ list level $in-level" if $!debug;
            }
            else {
                $rv ~= self.rendition('list', %( :items( @.itemlist.pop )  ));
                note "At $?LINE rendering with template ｢list｣ list level $in-level" if $!debug;
            }
            $top-level = @.itemlist.elems
        }
        note "At $?LINE rendering with template ｢$key｣ list level $in-level" if $!debug;
        $rv ~= self.rendition($key, %params);
        note "At $?LINE rv is { $rv.substr(0,150) } { '... (' ~ $rv.chars - 150 ~ ' more chars)' if $rv.chars > 150 } " if $!debug;
        $rv
    }

    my enum Context <None Glossary Heading HTML Raw Output>;
    #| Strip out formatting code and links from a Title or Link
    multi sub recurse-until-str(Str:D $s){ $s }
    multi sub recurse-until-str(Pod::Block $n){ $n.contents>>.&recurse-until-str().join }

    #| Multi for handling different types of Pod blocks.
    #| Most of the following code is adapted from Pod::To::BigPage rather than the original Pod::To:HTML
    multi sub handle (Pod::Block::Code $node, Int $in-level, ProcessedPod $pf, Context $context? = None  --> Str )  {
        note "At $?LINE node is { $node.WHAT.perl }" if $pf.debug;
        my $addClass = $node.config && $node.config<class> ?? ' ' ~ $node.config<class> !! '';
        # first completion is to flush a retained list before the contents of the block are processed
        my $retained-list = $pf.completion($in-level,'zero', %() );
        my $contents =  [~] $node.contents>>.&handle($in-level, $pf );
        my $t = $pf.completion($in-level, 'block-code', %( :$addClass, :$contents ) );
        {
            my $node = Pseudo.new(:$contents);
            if $pf.highlighter -> &cb {
                $t = cb :$node, default => sub ($node) {
                    $t
                }
            }
        }
        $retained-list ~ $t;
    }

    multi sub handle (Pod::Block::Comment $node, Int $in-level, ProcessedPod $pf, Context $context? = None  --> Str )  {
        note "At $?LINE node is { $node.WHAT.perl }" if $pf.debug;
        $pf.completion($in-level,'zero', %() ) ~ $pf.completion($in-level, 'zero', %( :contents([~] $node.contents>>.&handle($in-level, $pf )) ))
    }

    multi sub handle (Pod::Block::Declarator $node, Int $in-level, ProcessedPod $pf, Context $context? = None  --> Str )  {
        note "At $?LINE node is ", $node.WHAT.perl if $pf.debug;
        $pf.completion($in-level,'zero', %() ) ~ $pf.completion($in-level, 'notimplemented', %( :contents([~] $node.contents>>.&handle($in-level, $pf )) ))
    }

    multi sub handle (Pod::Block::Named $node, Int $in-level, ProcessedPod $pf, Context $context? = None  --> Str )  {
        note "At $?LINE node is { $node.WHAT.perl } with name { $node.name // 'na' }" if $pf.debug;
        my $target = $pf.register-toc( :1level, :text( $node.name.tclc ) );
        $pf.completion($in-level,'zero', %() ) ~ $pf.completion($in-level, 'named', %(
            :name($node.name),
            :$target,
            :1level,
            :contents( [~] $node.contents>>.&handle($in-level, $pf )),
            :top( $pf.top )
        ))
    }

    multi sub handle (Pod::Block::Named $node where $node.name.lc eq 'pod', Int $in-level, ProcessedPod $pf, Context $context? = None  --> Str )  {
        note "At $?LINE node is { $node.WHAT.perl } with name { $node.name // 'na' }" if $pf.debug;
        my $name = $pf.top eq $pf.default-top ?? $pf.default-top !! 'pod' ; # $pf.default-top, until TITLE changes it. Will fail if multiple pod without TITLE
        my $contents =
            $pf.completion($in-level, 'pod', %(
                :$name,
                :contents( [~] $node.contents>>.&handle($in-level, $pf )),
                :tail( $pf.completion(0, 'zero', %() ) )
            ))
    }

    multi sub handle (Pod::Block::Named $node where $node.name eq 'TITLE', Int $in-level, ProcessedPod $pf, Context $context? = None --> Str )  {
        note "At $?LINE node is { $node.WHAT.perl } with name { $node.name // 'na' }" if $pf.debug;
        my $addClass = ($node.config && $node.config<class> ?? ' ' ~ $node.config<class> !! '');
        my $text = $pf.title = $node.contents[0].contents[0].Str;
        $pf.top = $pf.register-toc(:1level, :$text, :is-title );
        my $target = $pf.top;
        $pf.completion($in-level,'zero', %() ) ~ $pf.completion($in-level, 'title', %( :$addClass, :$target, :$text  ) )
    }

    multi sub handle (Pod::Block::Named $node where $node.name eq 'SUBTITLE', Int $in-level, ProcessedPod $pf, Context $context? = None --> Str )  {
        note "At $?LINE node is { $node.WHAT.perl } with name { $node.name // 'na' }" if $pf.debug;
        my $addClass = ($node.config && $node.config<class> ?? ' ' ~ $node.config<class> !! '');
        my $contents = $pf.subtitle = [~] $node.contents>>.&handle($in-level,$pf, None);
        $pf.completion($in-level,'zero', %() ) ~ $pf.completion($in-level, 'subtitle', %( :$addClass, :$contents  ) )
    }

    multi sub handle (Pod::Block::Named $node where $node.name ~~ any(<VERSION DESCRIPTION AUTHOR SUMMARY>),
        Int $in-level, ProcessedPod $pf, Context $context? = None --> Str ) {
        note "At $?LINE node is { $node.WHAT.perl } with name { $node.name // 'na' }" if $pf.debug;
        $pf.register-meta(:name($node.name.lc), :value($node.contents[0].contents[0].Str));
        $pf.completion($in-level,'zero', %() )  # make sure any list is correctly ended.
    }

    multi sub handle (Pod::Block::Named $node where $node.name eq 'Html' , Int $in-level, ProcessedPod $pf, Context $context? = None --> Str )  {
        note "At $?LINE node is { $node.WHAT.perl } with name { $node.name // 'na' }" if $pf.debug;
        $pf.completion($in-level,'zero', %() ) ~ $pf.completion($in-level, 'raw', %( :contents( [~] $node.contents>>.&handle($in-level, $pf, HTML) )  ) )
    }

    multi sub handle (Pod::Block::Named $node where .name eq 'output', Int $in-level, ProcessedPod $pf, Context $context? = None  --> Str )  {
        note "At $?LINE node is { $node.WHAT.perl } with name { $node.name // 'na' }" if $pf.debug;
        $pf.completion($in-level,'zero', %() ) ~ $pf.completion($in-level, 'output', %( :contents( [~] $node.contents>>.&handle($in-level, $pf, Output) )  ) )
    }

    multi sub handle (Pod::Block::Named $node where .name eq 'Raw', Int $in-level, ProcessedPod $pf, Context $context? = None  --> Str )  {
        note "At $?LINE node is { $node.WHAT.perl } with name { $node.name // 'na' }" if $pf.debug;
        $pf.completion($in-level,'zero', %() ) ~ $pf.completion($in-level, 'raw', %( :contents( [~] $node.contents>>.&handle($in-level, $pf, Output) )  ) )
    }

    multi sub handle (Pod::Block::Para $node, Int $in-level, ProcessedPod $pf, Context $context where * == Output  --> Str )  {
        note "At $?LINE node is ", $node.WHAT.perl if $pf.debug;
        $pf.completion($in-level,'zero', %() ) ~ $pf.completion($in-level, 'raw', %( :contents( [~] $node.contents».&handle($in-level, $pf ) )  ) )
    }

    multi sub handle (Pod::Block::Para $node, Int $in-level, ProcessedPod $pf , Context $context? = None --> Str )  {
        note "At $?LINE node is ", $node.WHAT.perl if $pf.debug;
        my $addClass = ($node.config && $node.config<class> ?? ' ' ~ $node.config<class> !! '');
        $pf.completion($in-level,'zero', %() ) ~ $pf.completion($in-level, 'para', %( :$addClass, :contents( [~] $node.contents>>.&handle($in-level, $pf, $context ) )  ) )
    }

    multi sub handle (Pod::Block::Para $node, Int $in-level, ProcessedPod $pf, Context $context where * != None  --> Str )  {
        note "At $?LINE node is ", $node.WHAT.perl if $pf.debug;
        $pf.completion($in-level,'zero', %() ) ~ $pf.completion($in-level, 'raw', %( :contents( [~] $node.contents>>.&handle($in-level, $pf, $context) )  ) )
    }

    multi sub handle (Pod::Block::Table $node, Int $in-level, ProcessedPod $pf  --> Str )  {
        note "At $?LINE node is ", $node.WHAT.perl if $pf.debug;
        my $addClass = ($node.config && $node.config<class> ?? ' ' ~ $node.config<class> !! '');
        my @headers = gather for $node.headers { take .&handle($in-level, $pf ) };
        $pf.completion($in-level,'zero', %() ) ~ $pf.completion($in-level,  'table', %(
                :$addClass,
                :caption( $node.caption ?? $node.caption.&handle($in-level, $pf ) !! ''),
                :headers( +@headers ?? %( :cells( @headers ) ) !! Nil ),
                :rows( [ gather for $node.contents -> @r {
                    take %( :cells( [ gather for @r { take .&handle($in-level, $pf ) } ] )  )
                } ] ),
            ) )
    }

    multi sub handle (Pod::Defn $node, Int $in-level, ProcessedPod $pf, Context $context = None --> Str )  {
        note "At $?LINE node is ", $node.WHAT.perl if $pf.debug;
        my $addClass = ($node.config && $node.config<class> ?? ' ' ~ $node.config<class> !! '');
        $pf.completion($in-level,'zero', %() ) ~ $pf.completion($in-level, 'defn', %( :$addClass, :term($node.term), :contents( [~] $node.contents>>.&handle($in-level, $pf, $context ) )  ) )
    }

    multi sub handle (Pod::Heading $node, Int $in-level, ProcessedPod $pf --> Str )  {
        note "At $?LINE node is ", $node.WHAT.perl if $pf.debug;
        my $retained-list = $pf.completion($in-level,'zero', %() ); # process before contents
        my $addClass = ($node.config && $node.config<class> ?? ' ' ~ $node.config<class> !! '');
        my $level = $node.level;
        my $target = $pf.register-toc( :$level, :text( recurse-until-str($node).join ) ); # must register toc before processing content!!
        my $text = [~] $node.contents>>.&handle($in-level, $pf, Heading);
        $retained-list ~ $pf.completion($in-level, 'heading', {
            :$level,
            :$text, # we want all the formatting here
            :$addClass,
            :$target,
            :top( $pf.top )
        })
    }

    multi sub handle (Pod::Item $node, Int $in-level is copy, ProcessedPod $pf --> Str  )  {
        note "At $?LINE node is ", $node.WHAT.perl if $pf.debug;
        my $addClass = ($node.config && $node.config<class> ?? ' ' ~ $node.config<class> !! '');
        my $level = $node.level - 1;
        while $level < $in-level {
            --$in-level;
            $pf.itemlist[$in-level]  ~= $pf.rendition('list', %( :items( $pf.itemlist.pop ) ) )
        }
        while $level >= $in-level {
            $pf.itemlist[$in-level] = []  unless $pf.itemlist[$in-level]:exists;
            ++$in-level
        }
        $pf.itemlist[$in-level - 1 ].push: $pf.rendition('item', %( :$addClass, :contents([~] $node.contents>>.&handle($in-level, $pf ) )  ) );
        return '' # explicitly return an empty string because callers expecting a Str
    }

    multi sub handle (Pod::Raw $node, Int $in-level, ProcessedPod $pf --> Str )  {
        note "At $?LINE node is ", $node.WHAT.perl if $pf.debug;
        $pf.completion($in-level,'zero', %() ) ~ $pf.rendition('raw', %( :contents( [~] $node.contents>>.&handle($in-level, $pf ) )  ) )
    }

    multi sub handle (Str $node, Int $in-level, ProcessedPod $pf, Context $context? = None --> Str )  {
        note "At $?LINE node is ", $node.WHAT.perl, " node is \<$node>" if $pf.debug;
        $pf.completion($in-level,'zero', %() ) ~ $pf.rendition('escaped', %( :contents(~$node) ))
    }

    multi sub handle (Str $node, Int $in-level, ProcessedPod $pf, Context $context where * == HTML --> Str )  {
        note "At $?LINE node is ", $node.WHAT.perl if $pf.debug;
        $pf.completion($in-level,'zero', %() ) ~ $pf.rendition('raw', %( :contents(~$node) ))
    }

    multi sub handle (Nil)  {
        X::ProcessedPod::Unexpected-Nil.throw
    }

    multi sub handle (Pod::Config $node, Int $in-level, ProcessedPod $pf  --> Str )  {
        note "At $?LINE node is ", $node.WHAT.perl if $pf.debug;
        $pf.completion($in-level,'zero', %() ) ~ $pf.completion($in-level, 'comment',%( :contents($node.type ~ '=' ~ $node.config.perl)  ) )
    }

    multi sub handle (Pod::FormattingCode $node, Int $in-level, ProcessedPod $pf, Context $context where * == Raw   --> Str )  {
        note "At $?LINE node is { $node.WHAT.perl } with type { $node.type // 'na' }" if $pf.debug;
        $pf.completion($in-level, 'raw', %( :contents( [~] $node.contents>>.&handle($in-level, $pf, $context) )  ) )
    }

    multi sub handle (Pod::FormattingCode $node where .type ~~ none(<B C E Z I X N L P R T K U V>), Int $in-level, ProcessedPod $pf, Context $context where * == None   --> Str )  {
        note "At $?LINE node is { $node.WHAT.perl } with type { $node.type // 'na' }" if $pf.debug;
        $pf.completion($in-level, 'escaped', %( :contents( $node.type ~ '<' ~ [~] $node.contents>>.&handle($in-level, $pf, $context) ~ '>' )  ) )
    }

    multi sub handle (Pod::FormattingCode $node where .type eq 'B', Int $in-level, ProcessedPod $pf, Context $context = None   --> Str )  {
        note "At $?LINE node is { $node.WHAT.perl } with type { $node.type // 'na' }" if $pf.debug;
        my $addClass = $node.config && $node.config<class> ?? $node.config<class> !! '';
        $pf.completion($in-level, 'format-b',%( :$addClass, :contents( [~] $node.contents>>.&handle($in-level, $pf, $context) )  ))
    }

    multi sub handle (Pod::FormattingCode $node where .type eq 'C', Int $in-level, ProcessedPod $pf, Context $context? = None   --> Str )  {
        note "At $?LINE node is { $node.WHAT.perl } with type { $node.type // 'na' }" if $pf.debug;
        my $addClass = ($node.config && $node.config<class> ?? ' ' ~ $node.config<class> !! '');
        $pf.completion($in-level, 'format-c', %( :$addClass, :contents([~] $node.contents>>.&handle($in-level, $pf, $context ) )  ) )
    }

    multi sub handle (Pod::FormattingCode $node where .type eq 'C', Int $in-level, ProcessedPod $pf, Context $context where * ~~ Glossary   --> Str )  {
        note "At $?LINE node is { $node.WHAT.perl } with type { $node.type // 'na' }" if $pf.debug;
        $pf.completion($in-level, 'format-c-glossary', %( :contents( [~] $node.contents>>.&handle($in-level, $pf ) ) ))
    }

    multi sub handle (Pod::FormattingCode $node where .type eq 'E', Int $in-level, ProcessedPod $pf, Context $context? = None   --> Str )  {
        note "At $?LINE node is { $node.WHAT.perl } with type { $node.type // 'na' }" if $pf.debug;
        $pf.completion($in-level, 'raw', %( :contents( [~] $node.meta.map({ when Int { "&#$_;" }; when Str { "&$_;" }; $_ }) )  ) )
    }

    multi sub handle (Pod::FormattingCode $node where .type eq 'Z', Int $in-level, ProcessedPod $pf, $context = None   --> Str )  {
        note "At $?LINE node is { $node.WHAT.perl } with type { $node.type // 'na' }" if $pf.debug;
        $pf.completion($in-level, 'zero',%( :contents([~] $node.contents>>.&handle($in-level, $pf, $context))  ) )
    }

    multi sub handle (Pod::FormattingCode $node where .type eq 'I', Int $in-level, ProcessedPod $pf, Context $context = None   --> Str )  {
        note "At $?LINE node is { $node.WHAT.perl } with type { $node.type // 'na' }" if $pf.debug;
        my $addClass = $node.config && $node.config<class> ?? $node.config<class> !! '';
        $pf.completion($in-level, 'format-i',%( :$addClass, :contents( [~] $node.contents>>.&handle($in-level, $pf, $context) )  ))
    }

    multi sub handle (Pod::FormattingCode $node where .type eq 'X', Int $in-level, ProcessedPod $pf, Context $context = None   --> Str )  {
        note "At $?LINE node is { $node.WHAT.perl } with type { $node.type // 'na' }" if $pf.debug;
        my $addClass = $node.config && $node.config<class> ?? $node.config<class> !! '';
        my Bool $header = $context ~~ Heading;
        my $text = [~] $node.contents>>.&handle($in-level, $pf, $context);
        return ' ' unless $text or +$node.meta; # ignore if there is nothing that can be an entry
        my $target = $pf.register-glossary( recurse-until-str($node).join , $node.meta, $header );
        $pf.completion($in-level, 'format-x',%( :$addClass, :$text, :$target,  :$header  ) )
    }

    multi sub handle (Pod::FormattingCode $node where .type eq 'N', Int $in-level, ProcessedPod $pf, Context $context = None --> Str )  {
        note "At $?LINE node is { $node.WHAT.perl } with type { $node.type // 'na' }" if $pf.debug;
        my $text = [~] $node.contents>>.&handle($in-level, $pf,$context);
        $pf.completion($in-level, 'format-n', $pf.register-footnote(:$text) )
    }

    multi sub handle (Pod::FormattingCode $node where .type eq 'L', Int $in-level, ProcessedPod $pf, Context $context = None   --> Str )  {
        note "At $?LINE node is { $node.WHAT.perl } with type { $node.type // 'na' }" if $pf.debug;
        my $addClass = ($node.config && $node.config<class> ?? ' ' ~ $node.config<class> !! '');
        my $contents = [~] $node.contents>>.&handle($in-level, $pf, $context);
        my $target = $node.meta eqv [] | [""] ?? $contents !! $node.meta[0];
        $target = $pf.register-link( recurse-until-str($node).join, $target );
        # link handling needed here to deal with local links in global-link context
        $pf.completion($in-level, 'format-l', %( :$target, :$addClass, :contents([~] $node.contents>>.&handle($in-level, $pf, $context ) )  ) )
    }

    multi sub handle (Pod::FormattingCode $node where .type eq 'R', Int $in-level, ProcessedPod $pf, Context $context = None   --> Str )  {
        note "At $?LINE node is { $node.WHAT.perl } with type { $node.type // 'na' }" if $pf.debug;
        my $addClass = ($node.config && $node.config<class> ?? ' ' ~ $node.config<class> !! '');
        $pf.completion($in-level, 'format-r', %( :$addClass, :contents([~] $node.contents>>.&handle($in-level, $pf, $context ) )  ) )
    }

    multi sub handle (Pod::FormattingCode $node where .type eq 'T', Int $in-level, ProcessedPod $pf, Context $context = None   --> Str )  {
        note "At $?LINE node is { $node.WHAT.perl } with type { $node.type // 'na' }" if $pf.debug;
        my $addClass = ($node.config && $node.config<class> ?? ' ' ~ $node.config<class> !! '');
        $pf.completion($in-level, 'format-t', %( :$addClass, :contents([~] $node.contents>>.&handle($in-level, $pf, $context ) )  ) )
    }

    multi sub handle (Pod::FormattingCode $node where .type eq 'K', Int $in-level, ProcessedPod $pf, Context $context? = None   --> Str )  {
        note "At $?LINE node is { $node.WHAT.perl } with type { $node.type // 'na' }" if $pf.debug;
        my $addClass = ($node.config && $node.config<class> ?? ' ' ~ $node.config<class> !! '');
        $pf.completion($in-level, 'format-k', %( :$addClass, :contents([~] $node.contents>>.&handle($in-level, $pf, $context ) )  ) )
    }

    multi sub handle (Pod::FormattingCode $node where .type eq 'U', Int $in-level, ProcessedPod $pf, Context $context = None   --> Str )  {
        note "At $?LINE node is { $node.WHAT.perl } with type { $node.type // 'na' }" if $pf.debug;
        my $addClass = ($node.config && $node.config<class> ?? ' ' ~ $node.config<class> !! '');
        $pf.completion($in-level, 'format-u', %( :$addClass, :contents([~] $node.contents>>.&handle($in-level, $pf, $context ) )  ) )
    }

    multi sub handle (Pod::FormattingCode $node where .type eq 'V', Int $in-level, ProcessedPod $pf, Context $context = None  --> Str )  {
        note "At $?LINE node is { $node.WHAT.perl } with type { $node.type // 'na' }" if $pf.debug;
        $pf.completion($in-level, 'escaped', %( :contents([~] $node.contents>>.&handle($in-level, $pf, $context ) )  ) )
    }

    multi sub handle (Pod::FormattingCode $node where .type eq 'P', Int $in-level, ProcessedPod $pf, Context $context = None  --> Str )  {
        note "At $?LINE node is { $node.WHAT.perl } with type { $node.type // 'na' }" if $pf.debug;
        my Str $link-contents = recurse-until-str( $node );
        my $link = ($node.meta eqv [] | [""] ?? $link-contents !! $node.meta).Str;
        my URI $uri .= new($link);
        my Str $contents;
        my LibCurl::Easy $curl;
        my Bool $html = False;

        given $uri.scheme {
            when 'http' | 'https' {
                $curl .= new( :URL($link), :followlocation, :verbose($pf.verbose) );
                if $curl.perform.response-code ~~ / '2' \d\d / {
                    $contents = $curl.perform.content;
                }
                else {
                    $contents = "See: $link-contents";
                    note "Response code from ｢$link｣ is {  $curl.perform.response-code }" if $pf.verbose;
                }
            }
            when 'file' | '' {
                if $uri.path.Str.IO.f {
                    $contents = $uri.path.Str.IO.slurp;
                }
                else {
                    $contents = "See: $link-contents";
                    note "No file found at ｢$link｣" if $pf.debug;
                }
            }
            default {
                $contents = "See: $link-contents"
            }
        }
        CATCH {
            when X::LibCurl {
                #$contents = "Link ｢$link｣ caused LibCurl Exception, response code ｢{$curl.response-code}｣ with error ｢{$curl.error}｣";
                $contents = "See: $link-contents";
                note "Link ｢$link｣ caused LibCurl Exception, response code ｢{$curl.response-code}｣ with error ｢{$curl.error}｣" if $pf.verbose or $pf.debug;
            }
            default {
                $contents = "See: $link-contents";
                note "Link ｢$link｣ caused an exception with message ｢{ .message }｣" if $pf.verbose or $pf.debug;
            }
        }
        $html = so $contents ~~ / '<html' .+ '</html>'/;
        $contents = ~$/ if $html; # eliminate any chars outside the <html> container if there is one
        $pf.completion($in-level, 'format-p', %( :$contents, :$html ))
    }

    =begin takeout
            In S26 the following Pod specification was made. These are not completely followed in this Renderer.
        The reason is that not all of the url schemas have been thought necessary.

            A second kind of link—the P<> or placement link—works in the opposite direction. Instead of directing focus out to another document, it allows you to assimilate the contents of another document into your own.
        In other words, the P<> formatting code takes a URI and (where possible) inserts the contents of the corresponding document inline in place of the code itself.
        P<> codes are handy for breaking out standard elements of your documentation set into reusable components that can then be incorporated directly into multiple documents. For example:
        COPYRIGHT
        P<file:/shared/docs/std_copyright.pod>
        DISCLAIMER
        P<http://www.MegaGigaTeraPetaCorp.com/std/disclaimer.txt>
        might produce:
        Copyright
        This document is copyright (c) MegaGigaTeraPetaCorp, 2006. All rights reserved.
        Disclaimer
        ABSOLUTELY NO WARRANTY IS IMPLIED. NOT EVEN OF ANY KIND. WE HAVE SOLD YOU THIS SOFTWARE WITH NO HINT OF A SUGGESTION THAT IT IS EITHER USEFUL OR USABLE. AS FOR GUARANTEES OF CORRECTNESS...DON'T MAKE US LAUGH! AT SOME TIME IN THE FUTURE WE MIGHT DEIGN TO SELL YOU UPGRADES THAT PURPORT TO ADDRESS SOME OF THE APPLICATION'S MANY DEFICIENCIES, BUT NO PROMISES THERE EITHER. WE HAVE MORE LAWYERS ON STAFF THAN YOU HAVE TOTAL EMPLOYEES, SO DON'T EVEN *THINK* ABOUT SUING US. HAVE A NICE DAY.
        If a renderer cannot find or access the external data source for a placement link, it must issue a warning and render the URI directly in some form, possibly as an outwards link. For example:
        Copyright
        See: std_copyright.pod
        Disclaimer
        See: http://www.MegaGigaTeraPetaCorp.com/std/disclaimer.txt

        You can use any of the following URI forms (see Links) in a placement link:
            http: and https:
            file:
            man:
            doc:
            toc:

        The toc: form is a special pseudo-scheme that inserts a table of contents in place of the P<> code. After the colon, list the block types that you wish to include in the table of contents. For example, to place a table of contents listing only top- and second-level headings:

        P<toc: head1 head2>

        To place a table of contents that lists the top four levels of headings, as well as any tables:

        P<toc: head1 head2 head3 head4 table>

        To place a table of diagrams (assuming a user-defined Diagram block):

        P<toc: Diagram>

        Note also that, for P<toc:...>, all semantic blocks are treated as equivalent to head1 headings, and the =item1/=item equivalence is preserved.

        A document may have as many P<toc:...> placements as necessary.

        # NYI
        # multi sub handle (Pod::Block::Ambient $node) {
        #   $node.perl.say;
        #   $node.contents>>.&handle;
        # }
    =end takeout
