# Generic Renderer for POD files

Intended
- to be a plugin replacement for original Pod::To::HTML and to pass all its tests.
- use Templates for all output (P2HTML hard codes HTML)
- use the same API for outputting MarkDown and other output formats. Hence simply changing templates will generate new output
- generate Glossary, TOC and Footnote structures for each set of Pod trees.
- can be used to generate HTML and Markdown with raku's --doc flag.

## TOC, Footnotes, Glossaries and Links

Some explanations of terminology.

### TOC
A TOC or Table of Contents contains each Header text and a target within the document. For an HTML or MarkDown
file, the target will be an anchor name and will react to a mouse click.

For a dead tree format, or soft equivalent, the pointer will be a page number.

ProcessedPod create as TOC structure that is an array in the order the headers appear, with the lable, destination
anchor, return anchor and the level of the header.

### Glossary

A Glossary, or Index, is a list of words or phrases that may be used or defined in multiple places within a document
and which the author / editor considers would be useful to the reader when searching. Glossary structures are also
useful when creating SEARCH type functions.

The word 'index' is not used because in the HTML world, the file index.html is mostly used as the landing page for a
collection of documents and in most cases is a Table of Contents rather than a Glossary.

In a POD file, glossary texts are created with the X<> formatting code.

ProcessedPod creates a structure as a hash of the entry names (a single X<> can have multiple entry names pointing
to the same target), the destination anchors, the return anchor, and in the case where anchors are not possible,
a location consisting of the most recent header text.

### Footnotes

When an author wishes to give more explanation to a phrase without interupting the logic of the text, the information
is included in a footnote. In dead-tree formats, the footnotes tended to be at the end of a page (hence foot note).
In HTML for PCs/Laptops, a popular format was to include text to be shown by hovering a mouse. For smartphone
applications, hovering is not convenient, and other solutions are being found.

ProcessedPod creates an array in order of footnote creation with the number of the footnote, and target and return
anchors.

# More Information

See [RenderPod](renderpod.html) for the generic module and [Pod::To::HTML](pod2html.html) for the HTML 
specific module. `Pod::To::Markdown` follows `Pod::To::HTML` mostly.