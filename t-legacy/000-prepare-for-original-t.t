use Test;
use JSON::Fast;
plan 1;
my $orig-dir = 't-legacy';
for <class test multi> { ( "$orig-dir/$_.pod6").IO.copy: "t/$_.pod6" }
"t/templates".IO.mkdir;
"$orig-dir/templates/main.mustache".IO.copy: "t/templates/main.mustache";

ok 1, 'creating html templates to match original hard coded html of original P2HTML';
'html-templates.raku'.IO.spurt(q:to/CODE/);
    %(
        # note that verbatim V<> does not have its own format because it affects what is inside it (see POD documentation)
        'escaped' => -> %params {
            if ( %params<contents> ~~ /<[ & < > " ' {   ]>/ ) or ( %params<contents> ~~ / ' ' / ) {
                %params<contents> .= trans( [ q{&},     q{<},    q{>},    q{"},      q{'},      q{ }      ] =>
                                            [ q{&amp;}, q{&lt;}, q{&gt;}, q{&quot;}, q{&#39;} , q{&nbsp;} ] )
            }
            '{{{ contents }}}'
        },
        :raw('{{{ contents }}}'),

        'block-code' => q:to/TEMPL/,
            <pre class="pod-block-code{{# class }} {{ class }}{{/ class}}">{{# contents }}{{{ contents }}}{{/ contents }}</pre>
            TEMPL

        'comment' => '<!-- {{{ contents }}} -->',
        'declarator' => '<a name="{{ target }}"></a><article><code class="pod-code-inline">{{{ code }}}</code>{{{ contents }}}</article>',
        'dlist-start' => '<dl>
        ',
        'defn' => '<dt>{{ term }}</dt><dd><p>{{{ contents }}}</p></dd>',
        'dlist-end' => '</dl>
        ',
        'format-b' => '<strong{{# class }} class="{{ class }}"{{/ class }}>{{{ contents }}}</strong>',

        'format-c' => '<code{{# class }} class="{{ class }}"{{/ class }}>{{{ contents }}}</code>
        ',

        'format-i' => '<em{{# class }} class="{{ class }}"{{/ class }}>{{{ contents }}}</em>',

        'format-k' => '<kbd{{# class }}class="{{ class }}"{{/ class }}>{{{ contents }}}</kbd>
        ',

        'format-l' => '<a href="{{ target }}"{{# class }} class="{{ class }}"{{/ class}}>{{{ contents }}}</a>',

        'format-n' => '<sup><a name="{{ retTarget }}" href="#{{ fnTarget }}">[{{ fnNumber }}]</a></sup>
        ',

        'format-p' => '<div{{# class }} class="{{ class }}"{{/ class }}>{{^ html }}<pre>{{/ html }}{{{ contents }}}{{^ html }}</pre>{{/ html }}</div>',

        'format-r' => '<var{{# class }} class="{{ class }}"{{/ class }}>{{{ contents }}}</var>',

        'format-t' => '<samp{{# class }} class="{{ class }}"{{/ class }}>{{{ contents }}}</samp>',

        'format-u' => '<u{{# class }} class="{{ class }}"{{/ class }}>{{{ contents }}}</u>',

        'format-x' => '<a name="{{ target }}">{{# text }}<span class="glossary-entry{{# class }} {{ class }}{{/ class }}">{{{ text }}}</span></a>{{/ text }} ',

        'heading' => '<h{{# level }}{{ level }}{{/ level }} id="{{ target }}"><a class="u" href="#{{ top }}" title="go to top of document">{{{ text }}}</a></h{{# level }}{{ level }}{{/ level }}>
        ',

            'item' => '<li{{# class }} class="{{ class }}"{{/ class }}>{{{ contents }}}</li>
            ',

            'list' => q:to/TEMPL/,
                    <ul>
                        {{# items }}{{{ . }}}{{/ items}}
                    </ul>
                TEMPL

        'named' => q:to/TEMPL/,
                <section>
                    <h1>{{{ name }}}</h1>
                    {{{ contents }}}
                </section>
            TEMPL

        'notimplemented' => '<span class="pod-block-notimplemented">{{{ contents }}}</span>',

        'output' => '<pre class="pod-output">{{{ contents }}}</pre>',

        'para' => '<p{{# class }} class="{{ class }}"{{/ class }}>{{{ contents }}}</p>',

        'pod' => '{{# class }}<span class="{{ class }}">{{/ class }}{{{ contents }}}{{{ tail }}}{{# class }}</span>{{/ class }}',

        'section' => q:to/TEMPL/,
            <section>
            {{{ contents }}}{{{ tail }}}
            </section>
            TEMPL
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
                <head>
                    <title>{{ title }}</title>
                    <meta charset="UTF-8" />
                    {{# metadata }}{{{ metadata }}}{{/ metadata }}
                    {{# css }}<link rel="stylesheet" href="{{ css }}">{{/ css }}
                    {{ head }}
                </head>
                <body class="pod">
                    {{# toc }}{{{ toc }}}{{/ toc }}
                    {{# glossary }}{{{ glossary }}}{{/ glossary }}
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
                <table id="glossary">
                    <caption><h2 id="source-glossary">Glossary</h2></caption>
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
                    <caption><h2 id="TOC_Title">Table of Contents</h2></caption>
                    {{# toc }}
                    <tr class="toc-level-{{ level }}">
                        <td class="toc-text"><a href="#{{ target }}">{{ text }}</a></td>
                    </tr>
                    {{/ toc }}
                </table>
            TEMPL
            'header' => '<header>{{ title }}</header>',
            'footer' => '<footer><div>Rendered from <span class="path">{{ path }}{{^ path }}Unknown{{/ path}}</span></div>
                <div>at <span class="time">{{ renderedtime }}{{^ renderedtime }}a moment before time began!?{{/ renderedtime }}</span></div>
                </footer>',
    );
    CODE
