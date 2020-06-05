# Generic Renderer for POD files

Currently this project is still under development.

Intended
- to be a plugin replacement for original Pod::To::HTML and to pass all its tests.
- use Templates for all output (P2HTML hard codes HTML)
- use the same API for outputting MardDown and other output formats. Hence simply changing templates will generate new output
- if cached templates are available, will use cached templates rather than re-reading templates.
- generate Glossary, TOC and Footnote structures for each set of Pod trees.
- can be used to generate HTML and Markdown with raku's --doc flag.

This version relies heavily on a templating engine, (eg. Template::Mustache), and so caching is important.
The cannonical version of Template::Mustache is not cached. I have PR with a cached version.
Without caching, a large Pod file takes several seconds to render.

The version of Template::Mustache under finanalyst is a cached version.

Assuming the auth: "github:finanalyt" version is cloned to p6-Template-Mustache, then the following will work

```
prove -vre 'raku -Ilib -I../p6-Template-Mustache'
```

For more information look at the Pod in `lib/Pod/To/HTML`

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

### Links

A link contains both a text, which is shown to the reader, and an underlying target, usually of the form 'https://...'

POD also provides for links within a document, and also to documents within a collection of POD files.

There is a method 'register-links' which can be over-ridden in a subclass so that all links in a Processed Pod
document can be collected, eg. to test whether links are 'live'.