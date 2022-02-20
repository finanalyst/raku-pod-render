# MarkDown

----
----
## Table of Contents
[Usage with compiler](#usage-with-compiler)  
[Usage from a program](#usage-from-a-program)  
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

# Usage from a program
The class can be used from a program, such as [raku-pod-extraction](https://github.com/finanalyst/raku-pod-extraction).

# More detail and differences from Pod::To::HTML2
See [RenderPod](RenderPod.md) [PodToHTML2](PodToHTML2.md) for more detail. `Pod::To::MarkDown` has templates to produce MarkDown and not HTML. In addition:



*  A boolean `github-badge` (default: False) and an associated string `badge-path` (default: `'/actions/workflows/test.yaml/badge.svg'`) are provided. These will generate a badge at the start of a Pod6 file converted to Markdown, such as README.md, that will show the github badge.

*  The target rewrite function needs to be over-ridden.

*  MarkDown is not intended for internal links. So there is no glossary and META data is treated as paragraphs.

*  Footnotes have to be rendered at the end of the document, and there is no backward link from the footnote to the originating text.

*  Pod::To::MarkDown used the Mustache template system, not the Raku Closure Templates.





----
Rendered from MarkDown at 2022-02-20T14:28:59Z