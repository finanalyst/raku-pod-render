use v6;
%(
# the following are extra for HTML files and are needed by the render (class) method
# in the source-wrap template.
    '_templater' => 'MustacheTemplater',
    'camelia-img' => '<camelia />',
    'css' => '<style>debug</style>',
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
    'format-l' => '<a href="{{# external }}{{{ target }}}{{/ external }}{{# internal }}#{{ place }}{{/ internal }}{{# local }}{{ target }}.html{{# place }}#{{ place }}{{/ place}}{{/ local }}">{{{ link-label }}}</a>',
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
    'unknown-name' => q:to/TEMPL/,
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
