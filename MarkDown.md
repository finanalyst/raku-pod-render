# MarkDown
>
----
## Table of Contents
[Usage with compiler](#usage-with-compiler)  
[More detail and differences from Pod::To::HTML2](#more-detail-and-differences-from-podtohtml2)  

----
# Usage with compiler
From the terminal:

```
raku --doc=MarkDown input.raku > README.md

```
This takes the POD in the `input.raku` file, transforms it into MarkDown. This module uses the Mustache templating engine.

Some rendering options can be passed via the PODRENDER Environment variable. The options can be used to turn off components of the page.

```
PODRENDER='NoTOC NoFoot' raku --doc=MarkDown input.raku > README.md

```
The following regexen are applied to PODRENDER and switch off the default rendering of the respective section:


 | regex applied | if Match, then Turns off |
|:----:|:----:|
 | /:i 'no' '-'? 'toc' / | Table of Contents |
 | /:i 'no' '-'? 'meta' / | Meta information (eg AUTHOR) |
 | /:i 'no' '-'? 'footnotes' / | Footnotes. |

Any or all of 'NoTOC', 'NoMeta', or 'NoFoot' may be included in any order. Default is to include each section.

# More detail and differences from Pod::To::HTML2
See [RenderPod](RenderPod.md) [PodToHTML2](PodToHTML2.md) for more detail. `Pod::To::MarkDown` has templates to produce MarkDown and not HTML. In addition:



*  The target rewrite function needs to be over-ridden.

*  MarkDown is not intended for internal links. So there is no glossary and META data is treated as paragraphs.

*  Footnotes have to be rendered at the end of the document, and there is no backward link from the footnote to the originating text.

*  Pod::To::MarkDown used the Mustache template system, not the Raku Closure Templates.






----
Rendered from MarkDown at 2021-01-18T13:06:51Z