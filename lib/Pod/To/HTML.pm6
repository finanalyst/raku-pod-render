use v6.d;
use ProcessedPod;

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

class Pod::To::HTML is ProcessedPod {
    has $.css is rw;
    has $.head is rw; # Only needed for legacy P2HTML
    has $.def-ext is rw;
    has Bool $.debug is rw = False;
    # needed for HTML rendering

    #| render is a class method that is called by the raku compiler
    method render($pod-tree) {
        state $rv;
        return $rv with $rv;
        # Some implementations of raku/perl6 called the classes render method twice,
        # so it's necessary to prevent the same work being done repeatedly
        my $pp = self.new( :name($*PROGRAM-NAME) );
        # takes the pod tree and wraps it in HTML.
        $pp.process-pod($pod-tree);
        # Outputs a string that describes a html page
        $rv = $pp.source-wrap;
        # and store response so its not re-calculated
    }

    #| the constructor for this object
    submethod TWEAK(:$templates, :$css-type, :$css-src, :$css-url, :$favicon-src ) {
        $!def-ext = 'html';
        $!css = $_ with $css-url;
        my $css-text = $default-css-text;
        my $favicon-bin = $camelia-ico;
        my Bool $templates-needed = True;
        if $!debug {
            $camelia-svg = '<camelia />' ; # much less text for debugging
            $css-text = '<style>debug</style>'; # much less text for debugging
            $favicon-bin = '<meta>NoIcon</meta>';
        }
        with $templates {
            self.templates( $templates );
            $templates-needed = False
        }
        if $templates-needed and 'html-templates.raku'.IO.f {
            self.templates('html-templates.raku');
            $templates-needed = False
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
            $favicon-bin = $favicon-src.IO.slurp
        }
        self.templates( self.html-templates(:$css-text, :$favicon-bin) ) if $templates-needed ;
    }

    #| The Pod::To::HTML version, which uses css
    #| renders all of the document structures, and wraps them and the body
    #| uses the source-wrap template
    method source-wrap(--> Str) {
        self.render-structures;
        self.rendition('source-wrap', {
            :$.css,
            :$.head,
            :$.name,
            :$.title,
            :$.title-target,
            :$.subtitle,
            :$.metadata,
            :$.lang,
            :$.toc,
            :$.glossary,
            :$.footnotes,
            :$.body,
            :$.path,
            :$.renderedtime
        })
    }

    #| returns a hash of keys and Mustache templates
    #| Checks to see if in the working directory there is a file called html-templates.json. If so, then uses that data.
    #| html-templates.json is used for testing using tests from another Pod::To::HTML Module
    method html-templates( :$css-text = $default-css-text, :$favicon-bin = $camelia-ico ) {
        %(
        # the following are extra for HTML files and are needed by the render (class) method
        # in the source-wrap template.
            'camelia-img' => $camelia-svg,
            'css-text' => $css-text,
            'favicon' => '<link href="data:image/x-icon;base64,' ~ $favicon-bin ~ '" rel="icon" type="image/x-icon" />',
            # note that verbatim V<> does not have its own format because it affects what is inside it (see POD documentation)
            :escaped('{{ contents }}'),
            :raw('{{{ contents }}}'),
            'block-code' => q:to/TEMPL/,
                <pre class="pod-block-code{{# addClass }} {{ addClass }}{{/ addClass}}">
                {{# contents }}{{{ contents }}}{{/ contents }}</pre>
                TEMPL
            'comment' => '<!-- {{{ contents }}} -->',
            'dlist-start' => "<dl>\n",
            'defn' => '<dt>{{ term }}</dt><dd>{{{ contents }}}</dd>',
            'dlist-end' => "\n</dl>",
            'format-b' => '<strong{{# addClass }} class="{{ addClass }}"{{/ addClass }}>{{{ contents }}}</strong>',
            'format-c' => '<code{{# addClass }} class="{{ addClass }}"{{/ addClass }}>{{{ contents }}}</code>
            ',
            'format-i' => '<em{{# addClass }} class="{{ addClass }}"{{/ addClass }}>{{{ contents }}}</em>',
            'format-k' => '<kbd{{# addClass }}class="{{ addClass }}"{{/ addClass }}>{{{ contents }}}</kbd>
            ',
            'format-l' => '<a href="{{# internal }}#{{/ internal }}{{ target }}{{# local }}.html{{/ local }}">{{{ contents }}}</a>
            ',
            'format-n' => '<sup><a name="{{ retTarget }}" href="#{{ fnTarget }}">[{{ fnNumber }}]</a></sup>
            ',
            'format-p' => -> %params {
                %params<contents> = %params<contents>.=trans(['<pre>', '</pre>'] => ['&lt;pre&gt;', '&lt;/pre&gt;']);
                '<div{{# addClass }} class="{{ addClass }}"{{/ addClass }}><pre>{{{ contents }}}</pre></div>'
            },
            'format-r' => '<var{{# addClass }} class="{{ addClass }}"{{/ addClass }}>{{{ contents }}}</var>',
            'format-t' => '<samp{{# addClass }} class="{{ addClass }}"{{/ addClass }}>{{{ contents }}}</samp>',
            'format-u' => '<u{{# addClass }} class="{{ addClass }}"{{/ addClass }}>{{{ contents }}}</u>',
            'format-x' => '<a name="{{ target }}"></a>{{# text }}<span class="glossary-entry{{# addClass }} {{ addClass }}{{/ addClass }}">{{{ text }}}</span>{{/ text }} ',
            'heading' => '<h{{# level }}{{ level }}{{/ level }} id="{{ target }}"><a href="#{{ top }}" class="u" title="go to top of document">{{{ text }}}</a></h{{# level }}{{ level }}{{/ level }}>
            ',
            'item' => '<li{{# addClass }} class="{{ addClass }}"{{/ addClass }}>{{{ contents }}}</li>
            ',
            'list' => q:to/TEMPL/,

                <ul>
                    {{# items }}{{{ . }}}{{/ items}}
                </ul>
                TEMPL
            'named' => q:to/TEMPL/,
                <section>
                    <h{{# level }}{{ level }}{{/ level }} id="{{ target }}"><a href="#{{ top }}" class="u" title="go to top of document">{{{ name }}}</a></h{{# level }}{{ level }}{{/ level }}>
                    {{{ contents }}}
                </section>
                TEMPL
            'notimplemented' => '<span class="pod-block-notimplemented">{{{ contents }}}</span>',
            'output' => '<pre class="pod-output">{{{ contents }}}</pre>',
            'para' => '<p{{# addClass }} class="{{ addClass }}"{{/ addClass }}>{{{ contents }}}</p>',
            'pod' => '<section name="{{ name }}"{{# addClass }} class="{{ addClass }}"{{/ addClass }}>{{{ contents }}}{{{ tail }}}
                </section>',
            'section' => q:to/TEMPL/,
                <section name="{{ name }}">{{{ contents }}}{{{ tail }}}
                </section>
                TEMPL
            'subtitle' => '<div class="subtitle">{{{ subtitle }}}</div>',
            'table' => q:to/TEMPL/,
                <table class="pod-table{{# addClass }} {{ addClass }}{{/ addClass }}">
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
                        {{# toc }}{{{ toc }}}{{/ toc }}
                        {{# glossary }}{{{ glossary }}}{{/ glossary }}
                        </div>
                        {{> subtitle }}
                        <div class="pod-body{{^ toc }} no-toc{{/ toc }}">
                            {{{ body }}}
                        </div>
                        {{# footnotes }}{{{ footnotes }}}{{/ footnotes }}
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
                    {{# metadata }}{{{ metadata }}}{{/ metadata }}
                    {{# css }}<link rel="stylesheet" href="{{ css }}">{{/ css }}
                    {{^ css }}{{> css-text }}{{/ css }}
                    {{# head }}{{{ head }}}{{/ head }}
                </head>
                TEMPL
            'head' => '',
            'header' => '<header>{{> camelia-img }}{{> title }}</header>',
            'footer' => '<footer><div>Rendered from <span class="path">{{ path }}{{^ path }}Unknown{{/ path}}</span></div>
                <div>at <span class="time">{{ renderedtime }}{{^ renderedtime }}a moment before time began!?{{/ renderedtime }}</span></div>
                </footer>',
        )
    }
}

# The legacy Pod::To::HTML module assumes a different hightlighting callback to this module
# which makes fewer demands on the callback, therefore making it more generic.
# So the process of getting a rendering processor needs to be different from the
# one in the methods above.

# Legacy P2H highlighter is expected to be a callback, which is
# a sub expecting :node, which should have a method .contents, and :default
# which uses the value of node.contents to generate a string.

class Pseudo {
    has $.contents
};

sub get-processor {
    my $proc = Pod::To::HTML.new;
    if %*POD2HTML-CALLBACKS and %*POD2HTML-CALLBACKS<code>:exists {
        $proc.highlighter = sub ($contents) {
            my $node = Pseudo.new(:$contents);
            if %*POD2HTML-CALLBACKS<code> -> &cb {
                cb :$node, default => sub ($node) {
                    $node.contents
                }
            }
        }
    }
    $proc.css = 'assets/pod.css';
    $proc
}

#| Backwards compatibility for older Pod::To::HTML module
#| function renders a pod fragment
sub node2html($pod) is export {
    my $proc = get-processor;
    #$proc.debug = True;
    $proc.render-block($pod)
}

#| Function provided by older Pod::To::HTML module to encapsulate a pod-tree in a file
sub pod2html($pod, *%options) is export {
    my $proc = get-processor;
    with %options<templates> {
        if  "$_/main.mustache".IO ~~ :f {
            $proc.modify-templates(%( source-wrap => "$_/main.mustache".IO.slurp))
        }
        else {
            note "$_ does not contain required templates. Using default.";
        }
    }
    $proc.no-glossary = True;
    # old HTML did not provide a glossary
    #    $proc.debug = $proc.verbose = True;
    $proc.lang = $_ with %options<lang>;
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