use v6;
%(
    :_templater<CroTemplater>,
    :raw('<&HTML( .contents )>'),
    :escaped('<.contents>'),
    :block-code(q:to/TMPL/),
        <?.<highlight-contents>><.highlight-contents></?>
        <!.<highlight-contents>><pre class="pod-block-code">
            <.contents>
        </pre>
        </!>
        TMPL
    :camelia-img(q:to/TMPL/),
        <:sub camelia-img>
        <camelia /></:>
        TMPL
    :css(q:to/TMPL/),
        <:sub css>
        <style>debug</style></:>
        TMPL
    :head(q:to/TMPL/),
        <:sub head>
        </:>
        TMPL
    :favicon(q:to/TMPL/),
        <:sub favicon>
        <meta>NoIcon</meta></:>
        TMPL
    :comment(q:to/TMPL/),
        <&HTML('<!-- ' ~ .contents ~ ' -->')>
        TMPL
    :declarator(q:to/TMPL/),
        <a name="<.target>"></a>
        <article>
            <code class="pod-code-inline"><.code></code>
            <.contents>
        </article>
        TMPL
    :defn(q:to/TMPL/),
        <dt>
        <.term>
        </dt><dd>
        <.contents>
        </dd>
        TMPL
    :dlist-end('</dl>'),
    :dlist-start('<dl>'),
    :favicon(''),
    :footnotes(q:to/TMPL/),
        <?{.notes.elems > 0}><div id="_Footnotes" class="footnotes">
            <ul>
            <@notes><li id="<.fnTarget>" >
                <span class="footnote-number"><.fnNumber></span>
            <.text>
            <a class="footnote" href="#<.retTarget>" >« Back »</a></li>
            </@>
            </ul></div>
        </?>
        <!{.notes.elems > 0}>Has no elements</!>
        TMPL
    :format-b('<strong><.contents><strong>'),
    :format-c('<code><.contents><code>'),
    :format-i('<em><.contents><em>'),
    :format-k('<kbd><.contents><kbd>'),
    :format-l(q:to/TMPL/),
        <a href="<?.internal>#<.place></?><?.local>.html<?.place>#<.place></?></?>">
        <.link-label>
        </a>
        TMPL
    :format-n(q:to/TMPL/),
        <sup><a name="<.retTarget>" href="#<.fnTarget>">[<.fnNumber>]</a></sup>
        TMPL
    :format-p(q:to/TMPL/),
        <div><pre>
        <.contents>
        </pre></div>
        TMPL
    :format-r('<var><.contents><var>'),
    :format-t('<samp><.contents><samp>'),
    :format-u('<u><.contents><u>'),
    :format-x('<a name="<.target>"></a><?.text><span class="glossary-entry"><.text></span></?>'),
    :glossary(q:to/TMPL/),
        <?.glossary><div id="_Glossary" class="glossary">
        <div class="glossary-caption">Glossary</div>
        <div class="glossary-defn header">Term explained</div><div class="header glossary-place">In section</div>
            <@glossary>
                <div class="glossary-defn">
                <.text>
                </div>
                <@refs>
                  <div class="glossary-place"><a href="#<.target>"><?.<place>><.place></?></a></div>
                </@>
            </@>
        </div>
        </?>
        TMPL
    :heading(q:to/TMPL/),
        <:sub heading($level=1,:$close=False)>
        <?$close>/</?>h<$level></:>

        <<&heading(.level)> id="<.target>">
        <a href="#<.top>" class="u" title="go to top of document">
        <.text>
        </a>
        <<&heading(.level,:close)>>
        TMPL
    :image(q:to/TMPL/),
        <img src="<.src>"<?.width> width="<.width>"</?><?.height> height="<.height>"</?><?.alt> alt="<.alt>"</?>>')
        TMPL
    :item('<li><.contents></li>'),
    :list(q:to/TMPL/),
        <ul>
            <@items>
            <.item>
            </@>
        </ul>
        TMPL
    :meta(q:to/TMPL/),
        <@meta: $m>
            <meta name="<$m.name>" value="<$m.value>" />
        </@>
        TMPL
    :unknown-name(q:to/TMPL/),
        <:sub heading($level=1,:$close=False)><?$close>/</?>h<$level></:>
        <section>
            <<&heading(.level)> id="<.target>">
            <a href="#<.top>" class="u" title="go to top of document">
            <.name>
            </a><<&heading(.level, :close)>>
            <.contents><?.<tail>><.tail></?>
        </section>
        TMPL
    :output('<pre class="pod-output"><.contents></pre>'),
    :para('<p><.contents><p>'),
    :pod(q:to/TMPL/),
        <section name="<.name>">
        <.contents>
        <?.<tail>><.tail></?>
    </section>
    TMPL
    :source-wrap(q:to/TMPL/),
        <:use 'css'>
        <:use 'favicon'>
        <:use 'camelia-img'>
        <:use 'head'>

        <!doctype html>
        <html lang="<?.<lang>><.lang></?><!.<lang>>en</!>">
            <head>
                <title><.title></title>
                <meta charset="UTF-8">
                <&favicon>
                <.metadata>
                <&css>
                <&head>
            </head>
            <body class="pod">
                <header>
                    <&camelia-img>
                    <?.<title>><h1 class="title" id="<.title-target>" ><.title></h1></?>
                </header>
                <div class="pod-content">
                    <?{.toc or .glossary}><nav>
                        <.toc>
                        <.glossary>
                    </nav>
                    </?>
                    <?.<title-target>><div id="<.title-target>"></div></?>
                    <?.<subtitle>><div class="subtitle"><.subtitle></div></?>
                    <div class="pod-body<!.<toc>> no-toc</!>">
                        <.body>
                    </div>
                    <.footnotes>
                </div>
                <footer>
                    <div>Rendered from <span class="path"><?.<path>><.path></?><!.<path>><.name></!></span></div>
                    <div>at <span class="time"><?.renderedtime><.renderedtime></?><!.renderedtime>a moment before time began!?</!></span></div>
                </footer>
            </body>
        </html>
        TMPL
    :table(q:to/TMPL/),
        <table class="pod-table <?.<class>><.class></?>">
            <?.<caption>><caption><.caption></caption></?>
            <?.<headers>><thead><@headers>
                <tr>
                    <th><@cells><$_><:separator></th><th></:></@></th>
                </tr>
            </@></thead></?>
            <tbody>
                <@rows><tr>
                    <td><@cells><$_><:separator></td><td></:></@></td>
                </tr>
            </@></tbody>
        </table>
        TMPL
    :toc(q:to/TMPL/),
        <?.<toc>>
            <div id="_TOC">
            <table>
            <caption>Table of Contents</caption>
                <@toc>
                <tr class="toc-level-<.level>"><td class="toc-text"><a href="#<.target>"><.text></a></td></tr>
                </@>
            </table></div>
        </?>
        TMPL
);
