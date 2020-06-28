use v6.d;

class X::ProcessedPod::HTML::InvalidCSS::NoSpec is Exception {
    method message() { "If :css is supplied to processor method, so must :src" }
}
class X::ProcessedPod::HTML::InvalidCSS::BadSource is Exception {
    has $.fn;
    method message() { "$.fn does not exist as a text file" }
}
class X::ProcessedPod::HTML::InvalidCSS::BadType is Exception {
    has $.type;
    method message() { "Only 'load' or 'link' acceptable, got '$.type'" }
}

class Pod::To::HTML {
    use ProcessedPod;
    our $css-text = '<style>' ~ %?RESOURCES<pod.css>.slurp ~ '</style>'  ;
    our $camelia-svg = %?RESOURCES<Camelia.svg>.slurp; #'<img src="/images/Camelia.svg" alt="»ö«" id="logo" width="62" height="48">';

    method render($pod-tree) {
        state $rv;
        return $rv with $rv;
        # Some implementations of raku/perl6 called the classes render method twice,
        # so it's necessary to prevent the same work being done repeatedly

        my ProcessedPod $pp .= new(
            :templates(self.html-templates),
            :name($*PROGRAM-NAME)
        );
        # takes the pod tree and wraps it in HTML.
        $pp.process-pod($pod-tree);
        # Outputs a string that describes a html page
        $rv = $pp.source-wrap;
        # and store response so its not re-calculated
    }

    multi method processor( :$templates! ) {
        # providing new templates will eliminate the css functionality built into the default templates
        # but creating custom templates allows for css functionality any way.
        ProcessedPod.new(:$templates)
    }

    multi method processor( :$css!, :$src ) {
        X::ProcessedPod::HTML::InvalidCSS::NoSpec.new.throw and return Nil without $src;
        if $css eq 'load' {
            X::ProcessedPod::HTML::InvalidCSS::BadSource.new(:fn($src)).throw and return Nil
                unless $src.IO.f;
            $css-text = '<style>' ~ $src.IO.slurp ~ '</style>';
        }
        elsif $css eq 'link' {
            $css-text = '<link rel="stylesheet"  type="text/css" href="' ~ $src ~ '" media="screen" title="default" />'
        }
        else {
            X::ProcessedPod::HTML::InvalidCSS::BadType.new(:type($css)).throw;
            return Nil
        }
        ProcessedPod.new(:templates(self.html-templates))
    }

    multi method processor {
        return ProcessedPod.new(:templates('html-templates.raku')) if 'html-templates.raku'.IO.f; # automatically pick up templates if this file exists
        ProcessedPod.new(:templates(self.html-templates))
    }

    #| returns a hash of keys and Mustache templates
    #| Checks to see if in the working directory there is a file called html-templates.json. If so, then uses that data.
    #| html-templates.json is used for testing using tests from another Pod::To::HTML Module
    method html-templates {
        %(
            # templates that are used by process-pod
            # note that verbatim V<> does not have its own format because it affects what is inside it (see POD documentation)
            :escaped('{{ contents }}'),
            :raw('{{{ contents }}}'),

            'block-code' => q:to/TEMPL/,
                <pre class="pod-block-code{{# addClass }} {{ addClass }}{{/ addClass}}">
                {{# contents }}{{{ contents }}}{{/ contents }}</pre>
                TEMPL

            'comment' => '<!-- {{{ contents }}} -->',

            'defn' => '<dl><dt>{{ term }}</dt><dd>{{{ contents }}}</dd></dl>
            ',
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
                %params<contents> = %params<contents>.=trans( [ '<'   , '>'  ] => [ '&lt;', '&gt;' ]);
                '<div{{# addClass }} class="{{ addClass }}"{{/ addClass }}><pre>{{{ contents }}}</pre></div>'
            },

            'format-r' => '<var{{# addClass }} class="{{ addClass }}"{{/ addClass }}>{{{ contents }}}</var>',

            'format-t' => '<samp{{# addClass }} class="{{ addClass }}"{{/ addClass }}>{{{ contents }}}</samp>',

            'format-u' => '<u{{# addClass }} class="{{ addClass }}"{{/ addClass }}>{{{ contents }}}</u>',

            'format-x' => '{{^ header }}<a name="{{ target }}"></a>{{/ header }}{{# text }}<span class="glossary-entry{{# addClass }} {{ addClass }}{{/ addClass }}">{{{ text }}}</span>{{/ text }} ',

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
            'source-wrap' => q:to/TEMPL1/ ~ $css-text ~ q:to/TEMPL2/ ~ $camelia-svg ~ q:to/TEMPL3/,
                <!doctype html>
                <html lang="en">
                    <head>
                        <title>{{ title }}</title>
                        <meta charset="UTF-8" />
                TEMPL1
                    {{# metadata }}{{{ metadata }}}{{/ metadata }}
                    </head>
                    <body class="pod">
                        <header>
                TEMPL2
                        {{ title }}</header>
                        <div class="toc-glossary">
                        {{# toc }}{{{ toc }}}{{/ toc }}
                        {{# glossary }}{{{ glossary }}}{{/ glossary }}
                        </div>
                        <div class="pod-body{{^ toc }} no-toc{{/ toc }}">
                            {{{ body }}}
                        </div>
                        {{# footnotes }}{{{ footnotes }}}{{/ footnotes }}

                        <footer><div>Rendered from <span class="path">{{ path }}{{^ path }}Unknown{{/ path}}</span></div>
                             <div>at <span class="time">{{ renderedtime }}{{^ renderedtime }}a moment before time began!?{{/ renderedtime }}</span></div>
                        </footer>
                    </body>
                </html>
                TEMPL3

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
        )
    }
}

#| Backwards compatibility for older Pod::To::HTML module
sub node2html( $pod, :$debug = False ) is export {
    state $proc = Pod::To::HTML.processor ;
    $proc.debug = $debug;
    $proc.render-block( $pod )
}
#| Also provided by older Pod::To::HTML module
sub pod2html( $pod ) is export {
    node2html($pod)
}