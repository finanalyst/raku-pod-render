# MarkDown.pod6
>
----
## Table of Contents
[Head](#head)
[More detail and differences from Pod::To::HTML](#more-detail-and-differences-from-podtohtml)

----
# head

Usage with compiler

From the terminal:

```
raku --doc=MarkDown input.raku > README.md

```
Possibly the compiler may run the legacy `Pod::To::HTML` module. If so the following may work:

```
raku --doc=MarkDown2 input.raku > README.md

```
This takes the POD in the `input.raku` file, transforms it into MarkDown.

Some rendering options can be passed via the PODRENDER Environment variable. The options can be used to turn off components of the page.

```
PODRENDER='NoTOC NoFoot' raku --doc=MarkDown input.raku > README.md

```
The following regexen are applied to PODRENDER and switch off the default rendering of the respective section:


|regex applied|if Match, then Turns off|
|:----:|:----:|
|/:i 'no' '-'? 'toc' /|Table of Contents|
|/:i 'no' '-'? 'meta' /|Meta information (eg AUTHOR)|
|/:i 'no' '-'? 'footnotes' /|Footnotes.|

Any or all of 'NoTOC', 'NoMeta', or 'NoFoot' may be included in any order. Default is to include each section.

## More detail and differences from Pod::To::HTML
See [RenderPod](RenderPod.md) [PodToHTML](PodToHTML.md) for more detail. `Pod::To::MarkDown` has templates to produce MarkDown and not HTML. In addition:



*  The target rewrite function needs to be over-ridden.

*  MarkDown is not intended for internal links. So there is no glossary and META data is treated as paragraphs.

*  Footnotes have to be rendered at the end of the document, and there is no backward link from the footnote to the originating text.






----
Rendered from MarkDown.pod6 at 2020-07-12T20:27:55Z