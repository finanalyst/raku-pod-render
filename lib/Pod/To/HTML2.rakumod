use v6.d;
use ProcessedPod;
use RenderPod::Templating;
use RenderPod::Exceptions;

class X::ProcessedPod::HTML::InvalidCSS::NoSpec is Exception {
    method message() {
        "If :css-type is supplied to processor method, so must :css-src"
    }
}
class X::ProcessedPod::HTML::InvalidCSS::BadSource is Exception {
    has $.fn;
    method message() {
        "$.fn does not exist as a text file"
    }
}
class X::ProcessedPod::HTML::InvalidCSS::BadType is Exception {
    has $.css-type;
    method message() {
        "Only 'load' or 'link' acceptable, got '$.css-type'"
    }
}
class X::ProcessedPod::HTML::BadFavicon is Exception {
    has $.favicon-src;
    method message() {
        "The favicon source is unavailable, got '$.favicon-src'"
    }
}
# class variables as they used during object instantiation.
our $camelia-svg = %?RESOURCES<Camelia.svg>.slurp;
our $default-css-text = '<style>' ~ %?RESOURCES<pod.css>.slurp ~ '</style>';
our $camelia-ico = %?RESOURCES<camelia-ico.bin>.slurp;

class Pod::To::HTML2 is ProcessedPod {
    # needed for HTML rendering
    has $.def-ext is rw;

    # Only needed for legacy P2HTML
    has $!head = '';
    method head () is rw {
        Proxy.new(
            FETCH => -> $ { $!head },
            STORE => -> $, Str:D $head {
                $!head = $head;
                self.modify-templates( self.templater.make-template-from-string(
                    %( :$head,  )
                    )
                );
            }
        )
    }
    has $!css = '';
    method css () is rw {
        Proxy.new(
            FETCH => -> $ { $!css },
            STORE => -> $, Str:D $css {
                $!css = $css;
                self.modify-templates(
                    self.templater.make-template-from-string( %( :$css, ) )
                )
            }
        )
    }

    #| render is a class method that is called by the raku compiler
    method render($pod-tree) {
        state $rv;
        return $rv with $rv;
        # Some implementations of raku/perl6 called the classes render method twice,
        # so it's necessary to prevent the same work being done repeatedly
        my $pp = self.new;
        $pp.pod-file.name = $*PROGRAM-NAME;
        # takes the pod tree and wraps it in HTML.
        $pp.process-pod($pod-tree);
        # Outputs a string that describes a html page
        $rv = $pp.source-wrap;
        # and store response so its not re-calculated
    }

    #| the constructor for this object
    submethod TWEAK(
            :$templates,
            :$css-type,
            :$css-src,
            :$css-url,
            :$favicon-src,
            :$highlight-code,
            :$head,
            Bool :$min-top = False) {
        my Bool $t-loaded = False;
        $!def-ext = 'html';
        my $css-text = $default-css-text;
        my $favicon-bin = $camelia-ico;
        my $favicon;
        self.custom = <Image>;
        self.highlight-code = $highlight-code with $highlight-code;
        with $templates {
            self.templates($templates);
            $t-loaded = True;
        }
        # specified templates over-ride templates in a directory file
        if ! $t-loaded and 'html-templates.raku'.IO.f {
            self.templates('html-templates.raku');
            $t-loaded = True;
        }
        with $css-type {
            X::ProcessedPod::HTML::InvalidCSS::NoSpec.new.throw and return Nil without $css-src;
            given $css-type {
                when 'load' {
                    X::ProcessedPod::HTML::InvalidCSS::BadSource.new(:fn($css-src)).throw and return Nil
                    unless $css-src.IO.f;
                    $css-text = '<style>' ~ $css-src.IO.slurp ~ '</style>';
                }
                when 'link' {
                    $css-text = '<link rel="stylesheet"  type="text/css" href="' ~ $css-src ~ '" media="screen" title="default" />'
                }
                default {
                    X::ProcessedPod::HTML::InvalidCSS::BadType.new(:$css-type).throw;
                    return Nil
                }
            }
        }
        with $favicon-src {
            X::ProcessedPod::HTML::BadFavicon.new(:$favicon-src).throw
            unless $favicon-src.IO.f;
            $favicon-bin = $favicon-src.IO.slurp;
        }
        $favicon = '<link href="data:image/x-icon;base64,'
                ~ $favicon-bin
                ~ '" rel="icon" type="image/x-icon" />';
        self.templates(self.html-templates)
            unless $t-loaded;
        # modify the templates to include css, camelia, and favicon settings
        # unless turned off by min-top
        self.modify-templates( self.templater.make-template-from-string(
                %( :$css-text, :$favicon, :camelia-img($camelia-svg) )  )
            ) unless $min-top;
        self.css = $_ with $css-url;
        self.head = $_ with $head;
    }

    #| returns a hash of keys and Raku closure template
    method html-templates {
        %(
        # the following are extra for HTML files and are needed by the render (class) method
        # in the source-wrap template.
            'escaped' => sub ( $s ) {
                if $s and $s ne ''
                { $s.trans(qw｢ <    >    &     " ｣ => qw｢ &lt; &gt; &amp; &quot; ｣) }
                else { '' }
            },
            'raw' => sub ( %prm, %tml ) { (%prm<contents> // '') },
            'camelia-img' => sub ( %prm, %tml ) { '<camelia />' },
            'css-text' => sub ( %prm, %tml ) { '<style>debug</style>' },
            'css' => sub ( %prm, %tml ) { '' },
            'head' => sub ( %prm, %tml ) { '' },
            'favicon' => sub ( %prm, %tml ) { '<meta>NoIcon</meta>' },
            'block-code' => sub ( %prm, %tml ) {
                if %prm<highlighted>:exists {
                    # a highlighter will add its own classes to the <pre> container
                    %prm<highlighted>
                }
                else {
                    '<pre class="pod-block-code">'
                        ~ %prm<contents>
                        ~ '</pre>'
                }
            },
            'comment' => sub ( %prm, %tml ) { '<!-- ' ~ (%prm<contents> // '') ~ ' -->' },
            'declarator' => sub ( %prm, %tml ) {
                '<a name="' ~ %tml<escaped>(%prm<target> // '')
                        ~ '"></a><article><code class="pod-code-inline">'
                        ~ ( %prm<code> // '') ~ '</code>' ~ (%prm<contents> // '') ~ '</article>'
            },
            'dlist-start' => sub ( %prm, %tml ) { "<dl>\n" },
            'defn' => sub ( %prm, %tml ) {
                '<dt>'
                        ~ %tml<escaped>(%prm<term> // '')
                        ~ '</dt><dd>'
                        ~ (%prm<contents> // '')
                        ~ '</dd>'
            },
            'dlist-end' => sub ( %prm, %tml ) { "\n</dl>" },
            'format-b' => gen-closure-template('strong'),
            'format-c' => gen-closure-template('code'),
            'format-i' => gen-closure-template('em'),
            'format-k' => gen-closure-template('kbd'),
            'format-r' => gen-closure-template('var'),
            'format-t' => gen-closure-template('samp'),
            'format-u' => gen-closure-template('u'),
            'para' => gen-closure-template('p'),
            'format-l' => sub ( %prm, %tml ) {
                # transform a local file with an internal target
                my $trg = %prm<target>;
                if %prm<local> {
                    if $trg ~~ / (<-[#]>+) '#' (.+) $ / {
                        $trg = "$0\.html\#$1";
                    }
                    else {
                        $trg ~= '.html'
                    }
                }
                elsif %prm<internal> {
                    $trg = "#$trg"
                }
                '<a href="'
                        ~ $trg
                        ~ '">'
                        ~ (%prm<contents> // '')
                        ~ '</a>'
            },
            'format-n' => sub ( %prm, %tml ) {
                '<sup><a name="'
                        ~ %tml<escaped>(%prm<retTarget>)
                        ~ '" href="#' ~ %tml<escaped>(%prm<fnTarget>)
                        ~ '">[' ~ %tml<escaped>(%prm<fnNumber>)
                        ~ "]</a></sup>\n"
            },
            'format-p' => sub ( %prm, %tml ) {
                '<div><pre>'
                        ~ (%prm<contents> // '').=trans(['<pre>', '</pre>'] => ['&lt;pre&gt;', '&lt;/pre&gt;'])
                        ~ "</pre></div>\n"
            },
            'format-x' => sub ( %prm, %tml ) {
                '<a name="' ~ (%prm<target> // '') ~ '"></a>'
                ~ ( ( %prm<text>.defined and %prm<text> ne '' ) ?? '<span class="glossary-entry">' ~ %prm<text> ~ '</span>' !! '')
            },
            'heading' => sub ( %prm, %tml ) {
                '<h' ~ (%prm<level> // '1')
                        ~ ' id="'
                        ~ %tml<escaped>(%prm<target>)
                        ~ '"><a href="#'
                        ~ %tml<escaped>(%prm<top>)
                        ~ '" class="u" title="go to top of document">'
                        ~ (( %prm<text>.defined && %prm<text> ne '') ?? %prm<text> !! '')
                        ~ '</a></h'
                        ~ (%prm<level> // '1')
                        ~ ">\n"
            },
            'image' => sub ( %prm, %tml ) { '<img src="' ~ (%prm<src> // 'path/to/image') ~ '"'
                    ~ ' width="' ~ (%prm<width> // '100px') ~ '"'
                    ~ ' height="' ~ (%prm<height> // 'auto') ~ '"'
                    ~ ' alt="' ~ (%prm<alt> // 'XXXXX') ~ '">'
            },
            'item' => sub ( %prm, %tml ) { '<li>' ~ (%prm<contents> // '') ~ "</li>\n" },
            'list' => sub ( %prm, %tml ) {
                "<ul>\n"
                        ~ %prm<items>.join
                        ~ "</ul>\n"
            },
            'named' => sub ( %prm, %tml ) {
                "<section>\n<h"
                        ~ (%prm<level> // '1') ~ ' id="'
                        ~ %tml<escaped>(%prm<target>) ~ '"><a href="#'
                        ~ %tml<escaped>(%prm<top> // '')
                        ~ '" class="u" title="go to top of document">'
                        ~ (( %prm<name>.defined && %prm<name> ne '' ) ?? %prm<name> !! '')
                        ~ '</a></h' ~ (%prm<level> // '1') ~ ">\n"
                        ~ (%prm<contents> // '')
                        ~ (%prm<tail> // '')
                        ~ "\n</section>\n"
            },
            'output' => sub ( %prm, %tml ) { '<pre class="pod-output">' ~ (%prm<contents> // '') ~ '</pre>' },
            'pod' => sub ( %prm, %tml ) {
                '<section name="'
                        ~ %tml<escaped>(%prm<name> // '') ~ '">'
                        ~ (%prm<contents> // '')
                        ~ (%prm<tail> // '')
                        ~ '</section>'
            },
            'table' => sub ( %prm, %tml ) {
                '<table class="pod-table'
                        ~ ( ( %prm<class>.defined and %prm<class> ne '' ) ?? (' ' ~ %tml<escaped>(%prm<class>)) !! '')
                        ~ '">'
                        ~ ( ( %prm<caption>.defined and %prm<caption> ne '' ) ?? ('<caption>' ~ %prm<caption> ~ '</caption>') !! '')
                        ~ ( ( %prm<headers>.defined and %prm<headers> ne '' ) ??
                ("\t<thead>\n"
                        ~ [~] %prm<headers>.map({ "\t\t<tr><th>" ~ .<cells>.join('</th><th>') ~ "</th></tr>\n"})
                        ~ "\t</thead>"
                ) !! '')
                        ~ "\t<tbody>\n"
                        ~ ( ( %prm<rows>.defined and %prm<rows> ne '' ) ??
                [~] %prm<rows>.map({ "\t\t<tr><td>" ~ .<cells>.join('</td><td>') ~ "</td></tr>\n" })
                !! '')
                        ~ "\t</tbody>\n"
                        ~ "</table>\n"
            },
            'top-of-page' => sub ( %prm, %tml ) {
                if %prm<title-target>:exists and %prm<title-target> ne '' {
                    '<div id="' ~ %tml<escaped>(%prm<title-target>) ~ '"></div>'
                }
                else { '' }
            },
            'title' => sub ( %prm, %tml) {
                if %prm<title>:exists and %prm<title> ne '' {
                    '<h1 class="title"'
                     ~ ((%prm<title-target>:exists and %prm<title-target> ne '')
                            ?? ' id="' ~ %tml<escaped>(%prm<title-target>) !! '' ) ~ '">'
                     ~ %prm<title> ~ '</h1>'
                }
                else { '' }
            },
            'subtitle' => sub ( %prm, %tml ) {
                if %prm<subtitle>:exists and %prm<subtitle> ne '' {
                    '<div class="subtitle">' ~ %prm<subtitle> ~ '</div>' }
                else { '' }
            },
            'source-wrap' => sub ( %prm, %tml ) {
                "<!doctype html>\n"
                        ~ '<html lang="' ~ ( ( %prm<lang>.defined and %prm<lang> ne '' ) ?? %tml<escaped>(%prm<lang>) !! 'en') ~ "\">\n"
                        ~ %tml<head-block>(%prm, %tml)
                        ~ "\t<body class=\"pod\">\n"
                        ~ %tml<header>(%prm, %tml)
                        ~ '<div class="pod-content">'
                        ~ (( (%prm<toc>.defined and %prm<toc>.keys) or (%prm<glossary>.defined and %prm<glossary>.keys) ) ?? '<nav>' !! '')
                        ~ (%prm<toc> // '')
                        ~ (%prm<glossary> // '')
                        ~ (( (%prm<toc>.defined and %prm<toc>.keys) or (%prm<glossary>.defined and %prm<glossary>.keys) ) ?? '</nav>' !! '')
                        ~ %tml<top-of-page>(%prm, %tml)
                        ~ %tml<subtitle>(%prm, %tml)
                        ~ '<div class="pod-body' ~ (( %prm<toc>.defined and %prm<toc>.keys ) ?? '' !! ' no-toc') ~ '">'
                        ~ (%prm<body> // '')
                        ~ "\t\t</div>\n"
                        ~ (%prm<footnotes> // '')
                        ~ '</div>'
                        ~ %tml<footer>(%prm, %tml)
                        ~ "\n\t</body>\n</html>\n"
            },
            'footnotes' => sub ( %prm, %tml ) {
                with %prm<notes> {
                    if %prm<notes>.elems {
                    "<div id=\"_Footnotes\" class=\"footnotes\">\n<ul>"
                            ~ [~] .map({ '<li id="' ~ %tml<escaped>($_<fnTarget>) ~ '">'
                            ~ ('<span class="footnote-number">' ~ ( $_<fnNumber> // '' ) ~ '</span>')
                            ~ ($_<text> // '')
                            ~ '<a class="footnote" href="#'
                            ~ %tml<escaped>($_<retTarget>)
                            ~ "\"> « Back »</a></li>\n"
                    })
                            ~ "\n</ul>\n</div>\n"
                    }
                    else { '' }
                }
                else { '' }
            },
            'glossary' => sub ( %prm, %tml ) {
                if %prm<glossary>.defined and %prm<glossary>.keys {
                    '<div id="_Glossary" class="glossary">' ~ "\n"
                            ~ '<div class="glossary-caption">Glossary</div>' ~ "\n"
                            ~ '<div class="glossary-defn header">Term explained</div><div class="header glossary-place">In section</div>'
                            ~ [~] %prm<glossary>.map({
                                '<div class="glossary-defn">'
                                ~ ($_<text> // '')
                                ~ '</div>'
                                ~ [~] $_<refs>.map({
                                    '<div class="glossary-place"><a href="#'
                                            ~ %tml<escaped>($_<target>)
                                            ~ '">'
                                            ~ ($_<place>.defined ?? $_<place> !! '')
                                            ~ "</a></div>\n"
                                })
                        })
                            ~ "</div>\n"
                }
                else { '' }
            },
            'meta' => sub ( %prm, %tml ) {
                with %prm<meta> {
                    [~] %prm<meta>.map({
                        '<meta name="' ~ %tml<escaped>( .<name> )
                                ~ '" value="' ~ %tml<escaped>( .<value> )
                                ~ "\" />\n"
                    })
                }
                else { '' }
            },
            'toc' => sub ( %prm, %tml ) {
                if %prm<toc>.defined and %prm<toc>.keys {
                    "<div id=\"_TOC\"><table>\n<caption>Table of Contents</caption>\n"
                            ~ [~] %prm<toc>.map({
                        '<tr class="toc-level-' ~ .<level> ~ '">'
                                ~ '<td class="toc-text"><a href="#'
                                ~ %tml<escaped>( .<target> )
                                ~ '">'
                                ~ %tml<escaped>(  $_<text> // '' )
                                ~ "</a></td></tr>\n"
                    })
                            ~ "</table></div>\n"
                }
                else { '' }
            },
            'head-block' => sub ( %prm, %tml ) {
                "\<head>\n"
                        ~ '<title>' ~ %tml<escaped>(%prm<title>) ~ "\</title>\n"
                        ~ '<meta charset="UTF-8" />' ~ "\n"
                        ~ %tml<favicon>({}, {})
                        ~ (%prm<metadata> // '')
                        ~ (  ( %tml<css>( {}, {} ) ne '' )
                            ?? ('<link rel="stylesheet" href="' ~ %tml<css>({}, {}) ~ '">')
                            !! %tml<css-text>({}, {})
                        )
                        ~ %tml<head>( {}, {} )
                        ~ "\</head>\n"
            },
            'header' => sub ( %prm,%tml) {
                '<header>' ~ %tml<camelia-img>(%prm, %tml) ~ '<h1 class="title">' ~ %prm<title> ~ '</h1></header>'
            },
            'footer' => sub ( %prm, %tml ) {
                '<footer><div>Rendered from <span class="path">'
                        ~ ( ( %prm<path>.defined && %prm<path> ne '')
                            ??
                            %tml<escaped>(%prm<path>)
                            !!
                            %tml<escaped>(%prm<name>) )
                        ~ '</span></div>'
                        ~ '<div>at <span class="time">'
                        ~ (( %prm<renderedtime>.defined && %prm<path> ne '') ?? %tml<escaped>(%prm<renderedtime>) !! 'a moment before time began!?')
                        ~ '</span></div>'
                        ~ '</footer>'
            },
        )
    }
}

class Pod::To::HTML2::Mustache is Pod::To::HTML2 {

    #| returns a hash of keys and Mustache templates
    method html-templates {
        %(
        # the following are extra for HTML files and are needed by the render (class) method
        # in the source-wrap template.
            'camelia-img' => '<camelia />',
            'css-text' => '<style>debug</style>',
            'css' => '',
            'head' => '',
            'favicon' => '<meta>NoIcon</meta>',
            # note that verbatim V<> does not have its own format because it affects what is inside it (see POD documentation)
            :escaped('{{ contents }}'),
            :raw('{{{ contents }}}'),
            # a highlighter will add its own classes to the <pre> container
            :block-code( q:to/BLOCK/
                {{# highlighted }}{{ highlighted }}{{/ highlighted }}
                {{^ highlighted }}<pre class="pod-block-code">{{ contents }}</pre>{{/ highlighted }}
                BLOCK
            ),
            'comment' => '<!-- {{{ contents }}} -->',
            'declarator' => '<a name="{{ target }}"></a><article><code class="pod-code-inline">{{{ code }}}</code>{{{ contents }}}</article>',
            'dlist-start' => "<dl>\n",
            'defn' => '<dt>{{ term }}</dt><dd>{{{ contents }}}</dd>',
            'dlist-end' => "\n</dl>\n",
            'format-b' => '<strong>{{{ contents }}}</strong>',
            'format-c' => '<code>{{{ contents }}}</code>
            ',
            'format-i' => '<em>{{{ contents }}}</em>',
            'format-k' => '<kbd>{{{ contents }}}</kbd>
            ',
            'format-l' => '<a href="{{# internal }}#{{/ internal }}{{ target }}{{# local }}.html{{/ local }}">{{{ contents }}}</a>',
            'format-n' => '<sup><a name="{{ retTarget }}" href="#{{ fnTarget }}">[{{ fnNumber }}]</a></sup>
            ',
            'format-p' => -> %params {
                %params<contents> = %params<contents>.=trans(['<pre>', '</pre>'] => ['&lt;pre&gt;', '&lt;/pre&gt;']);
                '<div><pre>{{{ contents }}}</pre></div>'
            },
            'format-r' => '<var>{{{ contents }}}</var>',
            'format-t' => '<samp>{{{ contents }}}</samp>',
            'format-u' => '<u>{{{ contents }}}</u>',
            'format-x' => '<a name="{{ target }}"></a>{{# text }}<span class="glossary-entry">{{{ text }}}</span>{{/ text }} ',
            'heading' => '<h{{# level }}{{ level }}{{/ level }} id="{{ target }}"><a href="#{{ top }}" class="u" title="go to top of document">{{{ text }}}</a></h{{# level }}{{ level }}{{/ level }}>
            ',
            'image' => '<img src="{{# src }}{{ src }}{{/ src }}{{^ src }}path/to/image{{/ src }}"'
                    ~ ' width="{{# width }}{{ width }}{{/ width }}{{^ width }}100px{{/ width }}"'
                    ~ ' height="{{# height }}{{ height }}{{/ height }}{{^ height }}auto{{/ height }}"'
                    ~ ' alt="{{# alt }}{{ alt }}{{/ alt }}{{^ alt }}XXXXX{{/ alt }}">',
            'item' => '<li>{{{ contents }}}</li>
            ',
            'list' => q:to/TEMPL/,
                <ul>
                    {{# items }}{{{ . }}}{{/ items}}
                </ul>
                TEMPL
            'named' => q:to/TEMPL/,
                <section>
                    <h{{ level }} id="{{ target }}"><a href="#{{ top }}" class="u" title="go to top of document">{{{ name }}}</a></h{{ level }}>
                    {{{ contents }}}
                </section>
                TEMPL
            'output' => '<pre class="pod-output">{{{ contents }}}</pre>',
            'para' => '<p>{{{ contents }}}</p>',
            'pod' => '<section name="{{ name }}">{{{ contents }}}{{{ tail }}}
                </section>',
            'subtitle' => '<div class="subtitle">{{{ subtitle }}}</div>',
            'table' => q:to/TEMPL/,
                <table class="pod-table{{# class }} {{ class }}{{/ class }}">
                    {{# caption }}<caption>{{{ caption }}}</caption>{{/ caption }}
                    {{# headers }}<thead>
                        <tr>{{# cells }}<th>{{{ . }}}</th>{{/ cells }}</tr>
                    </thead>{{/ headers }}
                    <tbody>
                        {{# rows }}<tr>{{# cells }}<td>{{{ . }}}</td>{{/ cells }}</tr>{{/ rows }}
                    </tbody>
                </table>
                TEMPL
            'title' => '<h1 class="title" id="{{ title-target }}">{{{ title }}}</h1>',
            # templates used by output methods, eg., source-wrap, file-wrap, etc
            'source-wrap' => q:to/TEMPL/,
                <!doctype html>
                <html lang="{{ lang }}">
                    {{> head-block }}
                    <body class="pod">
                        {{> header }}
                        <div class="toc-glossary">
                        {{{ toc }}}
                        {{{ glossary }}}
                        </div>
                        {{> subtitle }}
                        <div class="pod-body{{^ toc }} no-toc{{/ toc }}">
                            {{{ body }}}
                        </div>
                        {{{ footnotes }}}
                        {{> footer }}
                    </body>
                </html>
                TEMPL
            'footnotes' => q:to/TEMPL/,
                <div class="footnotes">
                    <ol>{{# notes }}
                        <li id="{{ fnTarget }}">{{{ text }}}<a class="footnote" href="#{{ retTarget }}"> « Back »</a></li>
                        {{/ notes }}
                    </ol>
                </div>
                TEMPL
            'glossary' => q:to/TEMPL/,
                <table id="Glossary">
                    <caption>Glossary</caption>
                    <tr><th>Term</th><th>Section Location</th></tr>
                    {{# glossary }}
                    <tr class="glossary-defn-row">
                        <td class="glossary-defn">{{{ text }}}</td><td></td></tr>
                        {{# refs }}<tr class="glossary-place-row"><td></td><td class="glossary-place"><a href="#{{ target }}">{{{ place }}}</a></td></tr>{{/ refs }}
                    {{/ glossary }}
                </table>
                TEMPL
            'meta' => q:to/TEMPL/,
                {{# meta }}
                    <meta name="{{ name }}" value="{{ value }}" />
                {{/ meta }}
                TEMPL
            'toc' => q:to/TEMPL/,
                <table id="TOC">
                    <caption>Table of Contents</caption>
                    {{# toc }}
                    <tr class="toc-level-{{ level }}">
                        <td class="toc-text"><a href="#{{ target }}">{{# counter }}<span class="toc-counter">{{ counter }}</span>{{/ counter }} {{ text }}</a></td>
                    </tr>
                    {{/ toc }}
                </table>
                TEMPL
            'head-block' => q:to/TEMPL/,
                <head>
                    <title>{{ title }}</title>
                    <meta charset="UTF-8" />
                    {{> favicon }}
                    {{{ metadata }}}
                    {{> css }}
                    {{> head }}
                </head>
                TEMPL
            'header' => '<header>{{> camelia-img }}{{> title }}</header>',
            'footer' => '<footer><div>Rendered from <span class="path">{{ path }}{{^ path }}Unknown{{/ path}}</span></div>
                <div>at <span class="time">{{ renderedtime }}{{^ renderedtime }}a moment before time began!?{{/ renderedtime }}</span></div>
                </footer>',
        )
    }
}

# All of the code below is solely to pass the legacy tests.

sub get-processor {
    my $proc = Pod::To::HTML2.new;
    $proc.css = 'assets/pod.css';
    $proc
}

#| Backwards compatibility for legacy Pod::To::HTML module
#| function renders a pod fragment
sub node2html($pod) is export {
    my $proc = get-processor;
    # $proc.debug = $proc.verbose = True;
    $proc.render-block($pod)
}

#| Function provided by legacy Pod::To::HTML module to encapsulate a pod-tree in a file
sub pod2html($pod, *%options) is export {
    my $proc = get-processor;
    with %options<templates> {
        if  "$_/main.mustache".IO.f {
            # this indirect method is needed to pass tests as HTML2 looks for
            # a template file in the root, which is in rakuclosure format, so
            # this over-rides the internal mustache templates.
            my $proc-m = Pod::To::HTML2::Mustache.new;
            $proc.templates( $proc-m.html-templates );
            $proc.modify-templates(%( source-wrap => "$_/main.mustache".IO.slurp))
        }
        else {
            note "$_ does not contain required templates. Using default.";
        }
    }
    $proc.no-glossary = True;
    # old HTML did not provide a glossary
    #    $proc.debug = $proc.verbose = True;
    $proc.pod-file.lang = $_ with %options<lang>;
    $proc.css = $_ with %options<css-url>;
    $proc.head = $_ with %options<head>;
    $proc.render-tree($pod);
    $proc.source-wrap
}

use Pod::Load;
multi sub render(IO::Path $file, |c) is export {
    my $x = load($file);
    pod2html($x)
}
multi sub render(Str $string, |c) is export {
    pod2html(load($string))
}