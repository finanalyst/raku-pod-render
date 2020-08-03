# UNNAMED
>
----
## Table of Contents
[Head](#head)
[Extract Pod in a Module to README.md](#extract-pod-in-a-module-to-readmemd)
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

# Extract Pod in a Module to README.md
The utility function `Extractor.raku` is provided to take POD6 in the input sources and turn it into either .md or .html files (eg. for github README.md files)

# More detail and differences from Pod::To::HTML
See [RenderPod](RenderPod.md) [PodToHTML](PodToHTML.md) for more detail. `Pod::To::MarkDown` has templates to produce MarkDown and not HTML. In addition:



*  The target rewrite function needs to be over-ridden.

*  MarkDown is not intended for internal links. So there is no glossary and META data is treated as paragraphs.

*  Footnotes have to be rendered at the end of the document, and there is no backward link from the footnote to the originating text.






----
Rendered from UNNAMED at 2020-08-02T21:24:46Z