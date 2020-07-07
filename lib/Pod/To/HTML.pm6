use v6.d;

no precompilation;

use ProcessedPod;

class X::ProcessedPod::HTML::InvalidCSS::NoSpec is Exception {
    method message() {
        "If :css is supplied to processor method, so must :src"
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
# class variables as they used during object instantiation.
our $camelia-svg =
        '<camelia />' ; # much less text for debugging
# %?RESOURCES<Camelia.svg>.slurp;
our $default-css-text =
        '<style>debug</style>'; # much less text for debugging
# '<style>' ~ %?RESOURCES<pod.css>.slurp ~ '</style>';

class Pod::To::HTML is ProcessedPod {
    has $.css is rw;
    has $.head is rw; # Only needed for legacy P2HTML
    # needed for HTML rendering

    #| render is a class method that is called by the raku compiler
    method render($pod-tree) {
        state $rv;
        return $rv with $rv;
        # Some implementations of raku/perl6 called the classes render method twice,
        # so it's necessary to prevent the same work being done repeatedly
        my $pp = ProcessedPod.new(
                :name($*PROGRAM-NAME)
                );
        $pp.templates(self.html-templates);
        # takes the pod tree and wraps it in HTML.
        $pp.process-pod($pod-tree);
        # Outputs a string that describes a html page
        $rv = $pp.source-wrap;
        # and store response so its not re-calculated
    }

    #| the constructor for this object
    submethod TWEAK(:$templates, :$css-type, :$src, :$css-url ) {
        $!css = $_ with $css-url;
        with $templates {
            self.templates( $templates );
        }
        without $templates {
            if 'html-templates.raku'.IO.f { self.templates('html-templates.raku') }
            else { self.templates( self.html-templates) }
        }
        with $css-type {
            X::ProcessedPod::HTML::InvalidCSS::NoSpec.new.throw and return Nil without $src;
            my $css-text;
            given $css-type {
                when 'load' {
                    X::ProcessedPod::HTML::InvalidCSS::BadSource.new(:fn($src)).throw and return Nil
                    unless $src.IO.f;
                    $css-text = '<style>' ~ $src.IO.slurp ~ '</style>';
                }
                when 'link' {
                    $css-text = '<link rel="stylesheet"  type="text/css" href="' ~ $src ~ '" media="screen" title="default" />'
                }
                default {
                    X::ProcessedPod::HTML::InvalidCSS::BadType.new(:$css-type).throw;
                    return Nil
                }
            }
            self.templates( self.html-templates(:$css-text) );
        }
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
    method html-templates( :$css-text = $default-css-text ) {
        %(
        # the following are extra for HTML files and are needed by the render (class) method
        # in the source-wrap template.
            'camelia-img' => $camelia-svg,
            'css-text' => $css-text,
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
            'format-l' => '<a href="{{ target }}"{{# addClass }} class="{{ addClass }}"{{/ addClass}}>{{{ contents }}}</a>
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
            'subtitle' => '<div class="subtitle{{# addClass }} {{ addClass }}{{/ addClass }}">{{{ contents }}}</div>',
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
            'title' => '<h1 class="title{{# addClass }} {{ addClass }}{{/ addClass }}" id="{{ target }}">{{{ text }}}</h1>',
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
                    {{# metadata }}{{{ metadata }}}{{/ metadata }}
                    {{# css }}<link rel="stylesheet" href="{{ css }}">{{/ css }}
                    {{^ css }}{{> css-text }}}{{/ css }}
                    {{# head }}{{{ head }}}{{/ head }}
                </head>
                TEMPL
            'head' => '',
            'header' => '<header>{{> camelia-img }}{{ title }}</header>',
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
    #    $proc.delete-pod-structure; # pod2html could be called multiple times in the same program.
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
