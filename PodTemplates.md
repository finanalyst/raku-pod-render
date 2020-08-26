# Templates needed for a Processed Pod.
>
----
## Table of Contents
[Minimum Set](#minimum-set)
[Table of Required templates, their parameters, and helper templates in Pod::To::HTML](#table-of-required-templates-their-parameters-and-helper-templates-in-podtohtml)
[Notes](#notes)
[Sample Templates for HTML using Mustache Template Engine](#sample-templates-for-html-using-mustache-template-engine)

----
# Minimum Set
The minimum set of templates is `block-code comment declarator defn dlist-end dlist-start escaped footnotes format-b format-c format-i format-k format-l format-n format-p format-r format-t format-u format-x glossary heading item list meta named output para pod raw source-wrap table toc`.

Almost all of these templates expect a parameter to be rendered, see the table below.

A verification tool exists to test whether all the templates exists, and whether the minimum parameters are rendered.

The developer may decide not to render a parameter. The verification tool will flag this with a warning.

If the minimum set of templates is not provided, the renderer will throw an error.

# Table of Required templates, their parameters, and helper templates in Pod::To::HTML
>Required templates and their normal parameters

 | Key | Parameter | Sub-param | Type | Description |
|:----:|:----:|:----:|:----:|:----:|
 | escaped |  |  |  | Should be a special case |
 |  | contents |  | String | String |
 | raw |  |  |  | Should be a special case |
 |  | contents |  | String | normally should return the contents unchanged |
 | block-code |  |  |  | template for code |
 |  | contents |  | String | A code body |
 | comment |  |  |  |  |
 |  | contents |  | String | will be made into a comment |
 | declarator |  |  |  | renders documentation on a sub or variable |
 |  | target |  | String | 'target' is used in the glossary to point to the content, like a TOC for a header |
 |  | code |  | String | the line of code that is being documented |
 |  | contents |  | String | the documentation |
 | dlist-start |  |  | String | the tag or code that starts a declaration list |
 | defn |  |  |  | renders and element of a definition list |
 |  | term |  | String | the term part of a definition |
 |  | contents |  | String | the definition body |
 | dlist-end |  |  | String | the end tag of a definition list |
 | format-b |  |  |  | bold |
 |  | contents |  | String |  |
 | format-c |  |  |  | inline code |
 |  | contents |  | String |  |
 | format-i |  |  |  | italic |
 |  | contents |  | String |  |
 | format-k |  |  |  | keyboard |
 |  | contents |  | String |  |
 | format-r |  |  |  | replace |
 |  | contents |  | String |  |
 | format-t |  |  |  | terminal |
 |  | contents |  | String |  |
 | format-u |  |  |  | underline |
 |  | contents |  | String |  |
 | para |  |  |  | The template for a normal paragraph |
 |  | contents |  | String | text in para block |
 | format-l |  |  |  | renders a link to somewhere else |
 |  | internal |  | Boolean | true if target is within document |
 |  | external |  | Boolean | true if target is not in local area, eg., an internet url |
 |  | target |  | String | The url of the link |
 |  | local |  | String | url is local to system (perhaps with implied file extension) |
 |  | contents |  | String | The text associated with the link, which should be read (may be empty) |
 | format-n |  |  |  | render the footnote for the text |
 |  | retTarget |  | String | The anchor name the footnote will target |
 |  | fnTarget |  | String | The target for the footnote text |
 |  | fnNumber |  | String | The footnote number as allocated by the renderer |
 | format-p |  |  |  | Renders arbitrary text at some url. |
 |  | contents |  | String | The text at the link indicated by P |
 |  | html |  | Boolean | if True, then contents is in HTML format |
 | format-x |  |  |  |  |
 |  | target |  | String | Anchor name the glossary item will target |
 |  | text |  | String | The text to be included (the text to be included in the glossary is in the glossary structure) |
 |  | header |  | Boolean | True if the glossary item is also a header |
 | heading |  |  |  | Renders a heading in the text |
 |  | level |  | String | The level of the heading |
 |  | target |  | String | The anchor which TOC will target |
 |  | top |  | String | Top of document target |
 |  | text |  | String | Text of the header |
 | item |  |  |  | Renders to a string an item block |
 |  | contents |  | String | contents of block |
 | list |  |  |  | renders a lest of items, |
 |  | items |  | Array | Of strings already rendered with the "item" template |
 | named |  |  |  | A named block is included in the TOC |
 |  | level |  | String | level of the header implied by the block = 1 |
 |  | target |  | String | The target in the text body to which the TOC entry points |
 |  | top |  | String | The top of the document for the Header to point to |
 |  | name |  | String | The Name of the block |
 |  | contents |  | String | The contents of the block |
 | output |  |  |  | Output block contents |
 |  | contents |  | String |  |
 | pod |  |  |  |  |
 |  | name |  | String | Like "named" |
 |  | contents |  | String | as "named" |
 |  | tail |  | String | any remaining list at end of pod not triggered by next pod statement |
 | table |  |  |  | renders table with hash of keys |
 |  | caption |  | String | possibly empty caption |
 |  | headers |  | Array | of hash with key 'cells' |
 |  |  | cells | Array | Of string elements, that are the headers |
 |  | rows |  | Array | Of cells for the table body |
 |  |  | cells | Array | Of strings |
 | source-wrap |  |  |  | Turns all content to a string for a file |
 |  | name |  | String | Name of file |
 |  | title |  | String | Title for top of file / header |
 |  | subtitle |  | String | Subtitle string (if any) |
 |  | title-target |  | String | target name in text (may be same as top target) |
 |  | metadata |  | String | rendered metadata string |
 |  | lang |  | String | The language of the document (default 'en') |
 |  | toc |  | String | rendered TOC string |
 |  | glossary |  | String | rendered glossary string |
 |  | body |  | String | rendered body string |
 |  | footnotes |  | String | rendered footnotes string |
 |  | renderedtime |  | String | rendered time |
 |  | path |  | String | path to source file |
 | footnotes |  |  |  | renders the notes structure to a string |
 |  | notes |  | Array | Of hash with the following keys |
 |  |  | fnTarget | String | target in the footnote area |
 |  |  | text | String | text for the footnote |
 |  |  | retTarget | String | name for the anchor that the footnote will target |
 |  |  | fnNumber | String | The footnote number as allocated by the renderer |
 | glossary |  |  |  | renders the glossary structure to string |
 |  | glossary |  | Array | Of hash with keys |
 |  |  | text | String | text to be displayed in glossary (aka index) |
 |  |  | refs | Array | Of hash with keys |
 |  |  | (refs) target | String | target in text of one ref |
 |  |  | (refs) place | String | description of place in text of one ref (most recent header) |
 | toc |  |  |  | Renders the TOC structure to a string |
 |  | toc |  | Array | Of hash with keys: |
 |  |  | level | String | level of relevant header |
 |  |  | target | String | target in text where header is |
 |  |  | counter | String | formatted counter corresponding to level |
 |  |  | text | String | text of the header |
 | meta |  |  |  | renders the meta structure to a string that is then called metadata |
 |  | meta |  | Array | Of hash |
 |  |  | name | String | Name of meta data, eg. AUTHOR |
 |  |  | value | String | Value of key |

>Helper templates in Pod::To::HTML

 | Key | Parameter | Calls | Called-by | Description |
|:----:|:----:|:----:|:----:|:----:|
 | camelia-img |  |  | head-block | Returns the string $camelia-svg |
 | css-text |  |  | head-block | Returns the string $css-text |
 | favicon |  |  | head-block | Returns the string $favicon-bin |
 | image |  |  |  | Renders a Custom =Image Pod Block |
 |  | src |  |  | the src for the image |
 |  | width |  |  | Default width |
 |  | height |  |  | Default height |
 |  | alt |  |  | Default ALT text (when no image is loaded) |
 | title |  |  | head-block | Helper template to format title for text (title also used in header-block) |
 |  | title |  |  |  |
 |  | title-target |  |  |  |
 | subtitle |  |  | source-wrap | Helper template to format title for text |
 |  | subtitle |  |  |  |
 | head-block |  |  | source-wrap | Forms the text for the 'head' section |
 |  | title |  |  |  |
 |  | metadata |  |  |  |
 |  | css | css-text |  | if 'css' is empty, it calls css-text |
 |  | head |  |  |  |
 |  |  | favicon |  |  |
 | header |  |  | source-wrap | renders the header section for the body |
 |  |  | title |  |  |
 |  |  | camelia-img |  |  |
 | footer |  |  | source-wrap | renders the footer section for the body |
 |  | path |  |  | path to the source file |
 |  | renderedtime |  |  | time the source was rendered |

## Notes
*  All blocks pass any extra config parameters to the template, eg., 'class', as well but if a developer passes configuration data to a block, she will be able to use it in the template.

*  The template does not need to render a parameter, but the template verification tool will issue a warning if it does not.

*  required templates are called by the Renderer, but it is cleaner to break the template into sections. The templates for Pod::To::HTML do this, with footer, header and head-block templates, all of which are called by file-wrap. This structure is shown in the table above.

# Sample Templates for HTML using Mustache Template Engine
The following set includes an extra `Image` Custom Pod Block.

```
#| returns a hash of keys and Mustache templates
    method html-templates(:$css-text = $default-css-text, :$favicon-bin = $camelia-ico) {
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
                <pre class="pod-block-code">
                {{{ contents }}}</pre>
                TEMPL
            'comment' => '<!-- {{{ contents }}} -->',
            'declarator' => '<a name="{{ target }}"></a><article><code class="pod-code-inline">{{{ code }}}</code>{{{ contents }}}</article>',
            'dlist-start' => "<dl>\n",
            'defn' => '<dt>{{ term }}</dt><dd>{{{ contents }}}</dd>',
            'dlist-end' => "\n</dl>",
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
                    {{# css }}<link rel="stylesheet" href="{{ css }}">{{/ css }}
                    {{^ css }}{{> css-text }}{{/ css }}
                    {{{ head }}}
                </head>
                TEMPL
            'header' => '<header>{{> camelia-img }}{{> title }}</header>',
            'footer' => '<footer><div>Rendered from <span class="path">{{ path }}{{^ path }}Unknown{{/ path}}</span></div>
                <div>at <span class="time">{{ renderedtime }}{{^ renderedtime }}a moment before time began!?{{/ renderedtime }}</span></div>
                </footer>',
        )
    }

```







----
Rendered from PodTemplates at 2020-08-26T09:57:20Z