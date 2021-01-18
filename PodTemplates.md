# Templates needed for a Processed Pod.
>
----
## Table of Contents
[Minimum Set](#minimum-set)  
[Table of Required templates, their parameters, and helper templates in Pod::To::HTML2](#table-of-required-templates-their-parameters-and-helper-templates-in-podtohtml2)  
[Notes](#notes)  
[Sample Templates for HTML using Raku-Closure Template Engine](#sample-templates-for-html-using-raku-closure-template-engine)  

----
# Minimum Set
The minimum set of templates is `block-code comment declarator defn dlist-end dlist-start escaped footnotes format-b format-c format-i format-k format-l format-n format-p format-r format-t format-u format-x glossary heading item list meta named output para pod raw source-wrap table toc`.

Almost all of these templates expect a parameter to be rendered, see the table below.

A verification tool exists to test whether all the templates exists, and whether the minimum parameters are rendered.

The developer may decide not to render a parameter. The verification tool will flag this with a warning.

If the minimum set of templates is not provided, the renderer will throw an error.

# Table of Required templates, their parameters, and helper templates in Pod::To::HTML2
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

>Helper templates in Pod::To::HTML2

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

*  required templates are called by the Renderer, but it is cleaner to break the template into sections. The templates for Pod::To::HTML2 do this, with footer, header and head-block templates, all of which are called by file-wrap. This structure is shown in the table above.

# Sample Templates for HTML using Raku-Closure Template Engine
The following set includes an extra `Image` Custom Pod Block.

```
#| returns a hash of keys and Mustache templates
    method html-templates(:$css-text = $default-css-text, :$favicon-bin = $camelia-ico) {
        %(
        # the following are extra for HTML files and are needed by the render (class) method
        # in the source-wrap template.
            'escaped' => sub ( $s ) {
                if $s and $s ne ''
                { $s.trans(qw｢ <    >    &     " ｣ => qw｢ &lt; &gt; &amp; &quot; ｣) }
                else { '' }
            },
            'raw' => sub ( %prm, %tml ) { (%prm<contents> // '') },
            'camelia-img' => sub ( %prm, %tml ) {
                if $.min-top { '<camelia />' }
                else { $camelia-svg }
            },
            'css-text' => sub ( %prm, %tml ) {
                if $.min-top { '<style>debug</style>' }
                else { $css-text }
            },
            'favicon' => sub ( %prm, %tml ) {
                if $.min-top { '<meta>NoIcon</meta>' }
                else { '<link href="data:image/x-icon;base64,' ~ $favicon-bin ~ '" rel="icon" type="image/x-icon" />' }
            },
            'block-code' => sub ( %prm, %tml ) {
                my $contents = %prm<contents>;
                if $.highlight-code {
                    # a highlighter will add its own classes to the <pre> container
                    $.highlight.( $contents )
                }
                else {
                    '<pre class="pod-block-code">'
                            ~ ($contents // '')
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
                '<a href="'
                        ~ (%prm<internal> ?? '#' !! '')
                        ~ %prm<target>
                        ~ (%prm<local> ?? '.html'!! '')
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
                        ~ (( %prm<toc>.defined or %prm<glossary>.defined ) ?? '<div class="toc-glossary">' !! '')
                        ~ (%prm<toc> // '')
                        ~ (%prm<glossary> // '')
                        ~ (( %prm<toc>.defined or %prm<glossary>.defined ) ?? '</div>' !! '')
                        ~ %tml<subtitle>(%prm, %tml)
                        ~ '<div class="pod-body' ~ (( %prm<toc>.defined and %prm<toc> ne '' ) ?? '' !! ' no-toc') ~ '">'
                        ~ (%prm<body> // '')
                        ~ "\t\t</div>\n"
                        ~ (%prm<footnotes> // '')
                        ~ %tml<footer>(%prm, %tml)
                        ~ "\n\t</body>\n</html>\n"
            },
            'footnotes' => sub ( %prm, %tml ) {
                with %prm<notes> {
                    "<div class=\"footnotes\">\n<ol>"
                            ~ [~] .map({ '<li id="' ~ %tml<escaped>($_<fnTarget>) ~ '">'
                            ~ ($_<text> // '')
                            ~ '<a class="footnote" href="#'
                            ~ %tml<escaped>($_<retTarget>)
                            ~ "\"> « Back »</a></li>\n"
                    })
                            ~ "\n</ol>\n</div>\n"
                }
                else { '' }
            },
            'glossary' => sub ( %prm, %tml ) {
                if %prm<glossary>.defined {
                    '<div class="glossary">' ~ "\n"
                            ~ '<div class="glossary-caption">Glossary</div>' ~ "\n"
                            ~ '<div class="glossary-defn">Term explained</div><div class="glossary-location">In section</div>'
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
                if %prm<meta>.defined {
                    [~] %prm<meta>.map({
                        '<meta name="' ~ %tml<escaped>( .<name> )
                                ~ '" value="' ~ %tml<escaped>( .<value> )
                                ~ "\" />\n"
                    })
                }
                else { '' }
            },
            'toc' => sub ( %prm, %tml ) {
                if %prm<toc>.defined {
                    "<table id=\"TOC\">\n<caption>Table of Contents</caption>\n"
                            ~ [~] %prm<toc>.map({
                        '<tr class="toc-level-' ~ .<level> ~ '">'
                                ~ '<td class="toc-text"><a href="#'
                                ~ %tml<escaped>( .<target> )
                                ~ '">'
                                ~ ' ' ~ %tml<escaped>(  $_<text> // '' )
                                ~ "</a></td></tr>\n"
                    })
                            ~ "</table>\n"
                }
                else { '' }
            },
            'head-block' => sub ( %prm, %tml ) {
                "\<head>\n"
                        ~ '<title>' ~ %tml<escaped>(%prm<title>) ~ "\</title>\n"
                        ~ '<meta charset="UTF-8" />' ~ "\n"
                        ~ %tml<favicon>(%prm, %tml)
                        ~ (%prm<metadata> // '')
                        ~ (  ( %prm<css>.defined and %prm<css> ne '' )
                            ?? ('<link rel="stylesheet" href="' ~ %prm<css> ~ '">')
                            !! %tml<css-text>(%prm, %tml)
                        )
                        ~ (%prm<head> // '')
                        ~ "\</head>\n"
            },
            'header' => sub ( %prm,%tml) {
                '<header>' ~ %tml<camelia-img>(%prm, %tml) ~ %tml<title>(%prm, %tml) ~ '</header>'
            },
            'footer' => sub ( %prm, %tml ) {
                '<footer><div>Rendered from <span class="path">'
                        ~ (( %prm<path>.defined && %prm<path> ne '') ?? %tml<escaped>(%prm<path>) !! 'Unknown')
                        ~ '</span></div>'
                        ~ '<div>at <span class="time">'
                        ~ (( %prm<renderedtime>.defined && %prm<path> ne '') ?? %tml<escaped>(%prm<renderedtime>) !! 'a moment before time began!?')
                        ~ '</span></div>'
                        ~ '</footer>'
            },
        )
    }

```







----
Rendered from PodTemplates at 2021-01-17T14:06:21Z