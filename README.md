# Generic Pod Renderer
>Transforms POD in a Raku module/pod to HTML and MarkDown.


----
## Table of Contents
[Extractor GUI](#extractor-gui)
[Page Components](#page-components)
[TOC](#toc)
[Glossary](#glossary)
[Footnotes](#footnotes)
[Links](#links)
[Meta data](#meta-data)
[More Information](#more-information)

----
Intended

*  to be a plugin replacement for original Pod::To::HTML and to pass all its tests.

*  to use Templates for all output (legacy Pod::To::HTML hard codes HTML)

*  use the same API for outputting MarkDown and other output formats. Hence simply changing templates will generate new output

*  generate Glossary, TOC and Footnote structures for each set of Pod trees.

*  can be used to generate HTML and Markdown with raku's --doc flag.

*  has a GUI for converting one or more Pod6-containing files into MarkDown or HTML.

# Extractor GUI
Run `Extractor.raku` in the directory where the transformed files are needed. Select POD6 files by clicking on the FileChooser button at the top of the panel. The Output file name by default is the same as the basename of the input file, but can be changed. Select the output formats.

If a file was selected by mistake, uncheck the 'convert' box on the far left and it will not be processed.

When the list is complete, click on **Convert**. The converted files will be shown, or the failure message.

This tool is fairly primitive and it may not handle all error conditions. The tool is intended for generating md and html files in an adhoc manner.

# Page Components
A Pod6 source will generate body text and generate information for TOC, Footnotes, Glossaries, Links and Metadata

## TOC
A TOC or Table of Contents contains each Header text and a README.mdtarget within the document. For an HTML or MarkDown file, the target will be an anchor name and will react to a mouse click.

For a dead tree format, or soft equivalent, the pointer will be a page number.

ProcessedPod create as TOC structure that is an array in the order the headers appear, with the lable, destination anchor, return anchor and the level of the header.

## Glossary
A Glossary, or Index, is a list of words or phrases that may be used or defined in multiple places within a document and which the author / editor considers would be useful to the reader when searching. Glossary structures are also useful when creating SEARCH type functions.

The word 'index' is not used because in the HTML world, the file index.html is mostly used as the landing page for a collection of documents and in most cases is a Table of Contents rather than a Glossary.

In a POD file, glossary texts are created with the   formatting code.

ProcessedPod creates a structure as a hash of the entry names (a single   can have multiple entry names pointing to the same target), the destination anchors, the return anchor, and in the case where anchors are not possible, a location consisting of the most recent header text.

## Footnotes
When an author wishes to give more explanation to a phrase without interupting the logic of the text, the information is included in a footnote. In dead-tree formats, the footnotes tended to be at the end of a page (hence foot note). In HTML for PCs/Laptops, a popular format was to include text to be shown by hovering a mouse. For smartphone applications, hovering is not convenient, and other solutions are being found.

ProcessedPod creates an array in order of footnote creation with the number of the footnote, and target and return anchors.

## Links
Links can be

*  internal to the document

*  external to the site (eg. on the internet)

*  local to the site

Links should be tested. While the data is collected, verifying links is left to other modules.

## Meta data
Pod6 allows for metadata such as AUTHOR or VERSION to be set. These can be included in HTML or other formats.

# More Information
See [RenderPod](RenderPod.md) for the generic module and [Pod2HTML](Pod2HTML.md) for information about the HTML specific module ``Pod::To::HTML``. ``Pod::To::Markdown``, see [MarkDown](MarkDown.md), follows ``Pod::To::HTML`` mostly.








----
Rendered from README at 2020-08-05T16:50:54Z