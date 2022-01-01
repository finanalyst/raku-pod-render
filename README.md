# Generic Pod Renderer

----
----
## Table of Contents
[Installation](#installation)  
[Dependencies](#dependencies)  
[Page Components](#page-components)  
[TOC](#toc)  
[Glossary](#glossary)  
[Footnotes](#footnotes)  
[Links](#links)  
[Meta data](#meta-data)  
[RakuClosureTemplates](#rakuclosuretemplates)  
[Testing tool](#testing-tool)  
[HTML highlighting](#html-highlighting)  
[More Information](#more-information)  

----
[Badge](https://github.com/finanalyst/raku-pod-render/actions/workflows/test.yaml/badge.svg)

Intended

*  to provide a plugin replacement for the original (legacy) Pod::To::HTML and to pass all its tests.

*  to use templates for all output (legacy Pod::To::HTML hard codes HTML)

*  use the same API for outputting MarkDown and other output formats. Hence simply changing templates will generate new output

*  generate Glossary, TOC and Footnote structures for each set of Pod trees.

*  to generate HTML and Markdown with raku's --doc flag.

*  optionally to highlight Raku code at HTML generation time.

The Renderers, eg., Pod::To::HTML2, will chose the templating engine depending on the templates provided. So far only Template::Mustache and the new RakuClosureTemplates are handled, though other engines can be subclassed in.

# Installation
If highlighting is desired (see [Highlighting](Highlighting.md) below) from the start, an environment variable needs to be set (also see [Dependencies](Dependencies.md)).

```
POD_RENDER_HIGHLIGHTER=1 zef install Raku::Pod::Render
```
Since it is intended that `Raku::Pod::Render` can be used as a dependency for other modules, eg `raku-alt-documentation`, and it cannot be known whether all dependencies are installed, the default must be to prevent highlighting from being installed. If this is desired then,

```
zef install Raku::Pod::Render
```
will install the module without checking or installing a highlighter. If, **after default installation**, the highlighter is needed and _node & npm are installed_, then it can be installed by running the following in a terminal:

```
raku-render-install-highlighter
```
## Dependencies
The default highlighter at present is a Node based toolstack called **atom-perl-highlighter**. In order to install it automatically, `Raku::Pod::Render` requires an uptodate version of npm. The builder is known not to work with `node.js` > ****v13.0> and `npm` > **v14.15**.

For someone who has not installed `node` or `npm` before, or for whom they are only needed for the highlighter, the installation is ... confusing. It would seem at the time of writing that the easiest method is:

```
# Using Ubuntu
curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
sudo apt-get install -y nodejs
```
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

# RakuClosureTemplates
A new templating system is introduced to speed up the rendering. The Pod::To::HTML2 renderer is now slightly faster than the legacy Pod::To::HTML renderer, whilst achieving considerably more.

## Testing tool
A testing tool is included that will test the array of RakuClosureTemplates, including the possibility of specifying the structure of a custom template and testing it against the template.

# HTML highlighting
Raku code in HTML can be highlighted when HTML is generated. This requires the atom-perl6-highlighter developed by Samantha McVie. In the legacy Pod::To::HTML this is installed separately. This module will automatically install the highlighter unless specifically rejected by setting the POD_RENDER_NO_HIGHLIGHTER=1 environment variable.

The Build Module places the highlighter in the users directory at either (in order of preference)

*  .local/lib/raku-pod-render/highlights

*  .raku-pod-render/highlights

If the highlighter already exists at one of these locations, further installations of Raku-Pod-Render will not rebuild the stack.

This behaviour can be over-riden by

```
RAKU_POD_RENDER_FORCE_HIGHLIGHTER_REFRESH zef install Raku::Pod::Render
```
# More Information
See [RenderPod](RenderPod.md) for the generic module and [Pod2HTML](Pod2HTML.md) for information about the HTML specific module ``Pod::To::HTML2``. ``Pod::To::Markdown``, see [MarkDown](MarkDown.md), follows ``Pod::To::HTML2`` mostly.







----
Rendered from README at 2022-01-01T17:40:39Z