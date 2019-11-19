use v6.*;
use Template::Mustache;

use URI;
use LibCurl::Easy;

unit class ProcessedPod;

    class X::ProcessedPod::MissingTemplates is Exception {
        has @.missing;
        method message() {
            "The following templates should be supplied, but are not:\n"
                    ~ @.missing.join("\n")
        }
    }

    class X::ProcessedPod::Non-Existent-Template is Exception {
        has $.key;
        method message() { "Cannot process non-existent template ｢$.key｣" }
    }

    class X::ProcessedPod::Unexpected-Nil is Exception {
        method message() { "Unexpected handle with Nil value enountered" }
    }

    # template related variables independently of the templating system
    has %.tmpl;
    has @!required = < raw comment escaped glossary footnotes glossary-heading
            format-c block-code format-u para format-b named source-wrap defn output format-l
            format-x heading title format-n format-i format-k format-p meta list subtitle format-r
            format-t table item notimplemented glossary-entry section toc >;
    has $.engine; # slot for template engine. Should only be set in first call to rendition

    # defaults
    has $.default-top = '___top'; # the name of the anchor at the top of a source file
    has $!front-matter = 'Introduction'; # Text between =TITLE and first header

    has Bool $!in-defn-list = False; # used to register state when processing a definition list

    # provided at instantiation
    has &.highlighter; # a callable (eg. provided by external program) that converts [html] to highlighted raku code

    # provided at instantiation or by attributes on Class instance
    has Str $.name;
    has Str $.title is rw = $!name;
    has Str $.subtitle is rw = '';
    has Str $.path; # should be path of original document, defaults to $.name
    has Str $.top is rw = $!default-top; # defaults to top, then becomes target for TITLE
    has Bool $.no-meta is rw = False; # set to True eliminates meta data rendering
    has Bool $.no-footnotes is rw = False; # set to True eliminates rendering of footnotes
    has Bool $.no-toc is rw = False; # set to True to exclude TOC even if there are headers
    has Bool $.no-glossary is rw = False; # set to True to exclude Glossary even if there are internal anchors

    # supplied via process-pod
    has $!pod-tree; # pod tree supplied to renderer

    # populated by process-pod method
    has Str $.pod-body; # rendition of whole source, but not including toc or glossary
    has Str $.cum-pod-body = ''; # concatenation of multiple process calls
    has @.toc;
    has %.glossary;
    has @.links; # for links referenced
    has @.footnotes;
    has SetHash $.targets .= new; # target names are relative to Processed
    has Int @.counters is default(0);
    has Bool $.debug is rw;
    has Bool $.verbose;
    has @.itemlist; # for multilevel lists
    has @.metalist;

    submethod BUILD  (
            :$!name = 'UNNAMED',
            :%!tmpl,
            :$!title = $!name,
            :$!debug = False,
            :$!verbose = False,
            :$!path = $!name,
            :&!highlighter,
            ) { }

    submethod TWEAK {
        X::ProcessedPod::MissingTemplates.new(:missing( ( @!required (-) %!tmpl.keys ).keys )).throw
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
    }

    =comment rendition() is the only method that needs to be over-ridden for a different template system.

    method rendition(Str $key, %params --> Str) {
        $!engine = Template::Mustache.new without $!engine;

        return '' if $key eq 'zero';
        # special case this as there must be no EOL.

        X::ProcessedPod::Non-Existent-Template.new( :$key ).throw
                unless %!tmpl{$key}:exists;
        # templating engines like mustache do not handle logic or loops, which some Pod formats require.
        # hence we pass a Subroutine instead of a string in the template
        # the subroutine takes the same parameters as rendition and produces a mustache string
        $!engine.render(
                %!tmpl{ $key } ~~ Routine ?? %!tmpl{$key}( %params ) !! %!tmpl{$key}
                , %params, :literal )
    }

    =comment process-pod is called to populate the processed variables.

    method process-pod( $pod ) {
        $!pod-tree = $pod; # replace any pod, then process it
        $!pod-body = [~] $!pod-tree>>.&handle( 0, self );
        $!cum-pod-body ~= $!pod-body;
        self.filter-links;
    }

    =comment methods to provide output from a processed pod

    method body-only {
        $.pod-body
    }

    method last-body {
        $.cum-pod-body
    }

    method source-wrap {
        self.rendition('source-wrap', {
            :$!name,
            :orig-name($!name),
            :$!title,
            :$!subtitle,
            :metadata(self.render-meta),
            :toc( self.render-toc ),
            :glossary( self.render-glossary),
            :footnotes( self.render-footnotes ),
            :body( $!cum-pod-body ),
            :$!path,
            :time( DateTime(now).utc.truncated-to('seconds').Str )
        } )
    }

    method file-wrap(:$filename = $.name, :$ext = 'html' ) {
        "$filename\.$ext".IO.spurt: self.source-wrap
    }

    =comment methods to collect toc and glossary data

    method register-toc(:$level!, :$text!, Bool :$is-title = False --> Str) {
        @!counters[$level - 1]++;
        @!counters.splice($level);
        my $counter = @!counters>>.Str.join: '_';
        my $target = self.rewrite-target($text, :!unique ) ;
        @!toc.push: %( :$level, :$text, :$target, :$is-title, :$counter );
        $target
    }
    method render-toc( --> Str ) {
        # if no headers in pod, then no need to include a TOC
        return '' unless ( +@!toc and ! $.no-toc);
        self.rendition('toc', %( :toc( [@!toc.grep( { !( .<is-title>) } )] )  ));
    }
    method register-glossary(Str $text, @entries, Bool $is-header --> Str) {
        my $target;
        if $is-header {
            $target = @.toc[ * - 1 ]<target>
            # the last header to be added to the toc will have the url we want
        }
        else {
            # there must be something in either text or entries[0] to get here
            $target = @entries ?? @entries.join('-') !! $text;
            $target = self.rewrite-target($target, :unique)
        }
        my $place = @.toc ?? @.toc[ * - 1]<text> !! $!front-matter;
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
    method render-glossary(-->Str) {
        return '' unless ( +%!glossary.keys and ! $.no-glossary); #No render without any keys
        self.rendition( 'glossary', %( :glossary([gather for %!glossary.sort {  take %(:text(.key), :refs( [.value.sort] )) } ])  )  )
    }
    #TODO needs changing
    method register-link(Str $entry, Str $target is copy --> Str) {
        my $lable= $entry ?? $entry !! $target;
        $target = self.rewrite-target($target, :!unique);
        @!links.push: %( :$lable, :$target);
        $target
    }
    method register-footnote(:$text! --> Hash ) {
        my $fnNumber = +@!footnotes + 1;
        my $fnTarget = self.rewrite-target("fn$fnNumber",:unique) ;
        my $retTarget = self.rewrite-target("fnret$fnNumber",:unique);
        @!footnotes.push: %( :$text, :$retTarget, :$fnNumber, :$fnTarget  );
        (:$fnTarget, :$fnNumber, :$retTarget).hash
    }
    method render-footnotes(--> Str){
        return '' unless ( @!footnotes and ! $!no-footnotes ); # no rendering of code if no footnotes
        self.rendition('footnotes', %( :notes( @!footnotes )  ) )
    }
    method register-meta( :$name, :$value ) {
        @!metalist.push: %( :$name, :$value )
    }
    method render-meta {
        return '' unless ( @!metalist and ! $!no-meta );
        self.rendition('meta', %( :meta( @!metalist )  ))
    }

    method filter-links {
        # links have to be collected from the whole source before testing
        # remove from the links list all those that match an internal target
        # links to internal targets are specified with 1st char # in target
        # targets in glossary are stored without #
        my Set $internal .= new: gather for %.glossary.values -> @items { take .<target> for @items }
        @!links = gather for @!links {
            next if .<target> ~~ m/^ '#' $<tgt>=(.+) $ / and $internal{ $<tgt> }; #remove
            take %(:source($!name), :target( .<target> ), :lable( .<lable> ) )
        }
    }

    method rewrite-target(Str $candidate-name is copy, :$unique --> Str ) {
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
#}function GithubId(val) {
#            return val.toLowerCase().replace(/ /g,'-')
#		// single chars that are removed
#		.replace(/[`~!@#$%^&*()+=<>?,./:;"'|{}\[\]\\–—]/g, '')
#		// CJK punctuations that are removed
#		.replace(/[　。？！，、；：“”【】（）〔〕［］﹃﹄“”‘’﹁﹂—…－～《》〈〉「」]/g, '')
#}
        $candidate-name = $candidate-name.lc.subst(/\s+/,'_',:g);
        if $unique {
            $candidate-name ~= '_0' if $candidate-name (<) $!targets;
            ++$candidate-name while $!targets{$candidate-name}; # will continue to loop until a unique name is found
        }
        $!targets{ $candidate-name }++; # now add to targets, no effect if not unique
        $candidate-name
    }

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
                note "At $?LINE rv is $rv" if $!debug;
            }
            $top-level = @.itemlist.elems
        }
        note "At $?LINE rendering with template ｢$key｣ list level $in-level" if $!debug;
        $rv ~= self.rendition($key, %params);
        note "At $?LINE rv is $rv" if $!debug;
        $rv
    }

    my enum Context <None Glossary Heading HTML Raw Output>;

    multi sub recurse-until-str(Str:D $s){ $s } # strip out formating code and links
    multi sub recurse-until-str(Pod::Block $n){ $n.contents>>.&recurse-until-str().join }

    #| Multi for handling different types of Pod blocks.

    multi sub handle (Pod::Block::Code $node, Int $in-level, ProcessedPod $pf, Context $context? = None  --> Str )  {
        note "At $?LINE node is { $node.WHAT.perl }" if $pf.debug;
        my $addClass = $node.config && $node.config<class> ?? ' ' ~ $node.config<class> !! '';
        # first completion is to flush a retained list before the contents of the block are processed
        my $retained-list = $pf.completion($in-level,'zero', %() );
        my $contents =  [~] $node.contents>>.&handle($in-level, $pf );
        with $pf.highlighter { note "highlighter is defined";
            $retained-list ~ $pf.highlighter( $contents )
        }
        else {
            $retained-list ~ $pf.completion($in-level, 'block-code', %( :$addClass, :$contents ) )
        }
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
            :name($node.name.tclc),
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
        $pf.completion($in-level, 'section', %(
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
        my Str $link-contents = [~] $node.contents>>.&handle($in-level, $pf, $context);
        my $link = ($node.meta eqv [] | [""] ?? $link-contents !! $node.meta).Str;
        my URI $uri .= new($link);
        my Str $contents;
        given $uri.scheme {
            when 'http' | 'https' {
                my LibCurl::Easy $curl .= new( :URL($link), :followlocation, :verbose($pf.verbose) );
                CATCH {
                    when X::LibCurl {
                        $contents = "Link ｢$link｣ caused LibCurl Exception, response code ｢{$curl.response-code}｣ with error ｢{$curl.error}｣";
                        note $contents if $pf.verbose;
                    }
                }
                $contents = $curl.perform.content;
            }
            when 'file' | '' {
                if $uri.path.Str.IO.f {
                    $contents = $uri.path.Str.IO.slurp;
                }
                else {
                    $contents = "No file found at ｢$link｣";
                    note $contents if $pf.verbose;
                }
            }
            default {
                $contents = "Scheme ｢$_｣ is not implemented for P<$link-contents>"
            }
        } # Catch will resume here
        my $html = $contents ~~ m/ '<html' (.+) $ /;
        $contents = ('<html' ~ $/[0]) if $html;
        $pf.completion($in-level, 'format-p', %( :$contents, :$html ))
    }

    =begin takeout
            In S26:
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
