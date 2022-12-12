# Rendering Rakudoc (aka POD6) into HTML
>Renders Rakudoc sources into HTML using templates and plugins


## Table of Contents
[Requirements for HTML](#requirements-for-html)  
[Simple usage](#simple-usage)  
[Other templating systems](#other-templating-systems)  
[Usage with compiler](#usage-with-compiler)  
[Component options](#component-options)  
[Plugins options](#plugins-options)  
[Rakudoc-to-html](#rakudoc-to-html)  
[Examples and plugins](#examples-and-plugins)  
[Defaults and customisation](#defaults-and-customisation)  
[Template file](#template-file)  
[Plugins](#plugins)  
[Standalone usage mixing Pod and code](#standalone-usage-mixing-pod-and-code)  
[Custom blocks](#custom-blocks)  
[Latex-render](#latex-render)  
[Head](#head)  
[Adding customisation programmatically](#adding-customisation-programmatically)  
[Highlighting](#highlighting)  
[Templates](#templates)  
[Exported Subroutines](#exported-subroutines)  
[Why Reinvent the Wheel?](#why-reinvent-the-wheel?)  

----
A Rakudoc (once called POD6) document is rendered by Raku into a structure called a Pod-tree. A Pod-tree can also be constructed from the Rakudoc used to document a Raku program.

Pod::To::HTML2 converts the Pod-tree into an HTML file, or a fragment of Rakudoc into a fragment of HTML.

Pod::To::HTML2 is a subclass of **ProcessedPod**, which contains significantly more information about the Rakudoc in a file. See [the documentation of PodRender](PodRender.md) for more detail.

See the sister [Pod::To::MarkDown](Markdown.md) class for rendering a Rakudoc file to MarkDown.

A Pod-tree consists of Pod::Blocks. The contents and metadata associated with each block is passed to a template with the same name as the block.

Templates are stored separately from the code in `Pod::To::HTML2` and so can be tweaked by the user.

Rakudoc can be customised by creating new named blocks and FormatCodes (see Raku documentation on POD6). The `Pod::To::HTML2` class enables the creation of new blocks and FormatCodes via [plugins](plugins). Several non-standard Blocks are included to show how this is done.

The rationale for re-writing the whole **Pod::To::HTML** module is in the section [Why Reinvent the Wheel?](why-reinvent-the-wheel?).

`Pod::To::HTML2` implements three of the subs in `Pod::To::HTML`, namely:

*  node2html <pod block> # convert a string of pod to a string of html

*  pod2html <pod tree> # converts a pod block to a string of html

*  render # converts a file to html

However, `pod2html` and `render` have a variety of options that are not supported by HTML2 because they depend on Mustache templates and the plugins for HTML2 have not yet been fully completed to work with Mustache templates. This is a TODO.

A utility called `Rakudoc-to-html` is included in the distribution to transform a local Rakudoc file# to HTML. Try `Rakudoc-to-html Example` in an empty directory! See below for more information.

# Requirements for HTML
To render a Rakudoc file into HTML, the following are needed:

*  Content in the form of a Pod-tree, OR a filename containing Rakudoc, which is then converted to a Pod-tree

*  templates that will generate HTML for each Pod Block

*  a favicon file

*  CSS content for rendering the HTML

*  images referenced in the CSS or content

*  Javascript or JQuery programs and libraries.

The HTML file must then be served together with the CSS, favicon.ico, script and image assets. This can be done in many different ways, eg, with a Cro App, but each has a different set of dependencies. It is assumed the user will know how to serve files once generated.

# Simple usage
This distribution assumes a user may want simplicity in order

*  to quickly render a single Rakudoc file

*  to tweak/provide any of the templates, favicon, CSS

*  add plugins to create custom blocks

*  include the `=Image` named block and reference an image.

Anything more complex, such as another destination directory or handling more than one Rakudoc file, needs to be done by instantiating the underlying classes. An more complex example is the `Collection` module, which adds even more plugins. **Collection** _render_ plugins can be adapted for `Pod::To::HTML2`.

The utility `Rakudoc-to-html` in this distribution will render a Rakudoc file.

The utility creates the following in the directory where Rakudoc-to-html was called:

*  an html file with the same name as the Rakudoc file;

*  a sub-directory `assets_files` if not already present with:

	*  an `images` subdirectory with

		*  `favicon.ico` file, if it is **not** already present;

		*  the file `Camelia.svg` if it is **not** already present;

		*  images defined by plugins or [user images](image-management).

	*  a CSS subdirectory with:

		*  `rakudoc-styling.css` if it is **not** already present;

		*  css files defined for [plugins](plugins);

	*  a sub-directory `js` for js and jQuery scripts defined by plugins.

The default templates, favicon, plugins and rakudoc-styling css are installed when this distribution is installed into a directory called `$*HOME/.local/share/RenderPod`. (See [Defaults and customisation](defaults-and-customisation) for more detail.)

If files for html (See [Default and customisation](default-and-customisation)) are present in the current working directory, they will be used in place of the defaults in `$*HOME/.local/share/RenderPod`.

The recommended way to customise the templates/favicon/css/plugin files is to create an empty directory, use `Rakudoc-to-html get-local` to all plugins and templates from the default directory to the empty directory, modify them, then call `Rakudoc-to-html rakudoc-source.rakudoc` in that directory (source could include a path). The HTML file and its associated assets will be generated in the directory.

Plugins that don't need to be modified can be deleted locally.

If the Pod::To::HTML2 class is instantiated, or the Pod::To::HTML2 functions are used, then the default assets can be used, or taken from files in the Current Working Directory.

# Other templating systems
Three sets of the main default templates are available for the three templating engines automatically detected in this distribution:

*  `RakuClosure` template system, (default choice)

*  `Mustache` templating engine, (plugins do not work with Mustache) and

*  `Cro::WebApp::Template` engine (the interface with Crotmp is not fully developed).

The templating engine can be selected by calling `Rakudoc-to-html` with the `type` option set to

*  **crotmp** eg., `Rakudoc-to-html --type=crotmp`

*  **mustache**, eg., `Rakudoc-to-html --type='mustache'`.

*  **rakuclosure**, eg., `Rakudoc-to-html --type='rakuclosure'`.

It is possible to change the templates in a plugin to match the main templating engine. Plugins templates are specified for RakuClosureTemplates. But if there is a key 'RakuClosureTemplater', the templates will be taken from the Hash it points to. Then keys for other templating engines can also be included.

Todo: the plan is to include templates for each templating engine in the common plugins.

# Usage with compiler
From the terminal:

```
raku --doc=HTML2 input.raku > output.html

```
This takes the Rakudoc (aka POD6) in the `input.raku` file, transforms it into HTML, outputs a full HTML page including a Table of Contents, Glossary and Footnotes. As described in [Simple Usage](simple-usage), the `favicon.ico`, `rakudoc-styling.css`, image and additional CSS files are placed in subdirectories of the Current working directory.

This will only work with `rakuclosure` templates.

## Component options
Some rendering options can be passed via the RAKOPTS Environment variable.

*  The TOC, Glossary (Index), Meta and Footnotes can be turned off.

```
RAKOPTS='NoTOC NoMETA NoGloss NoFoot' raku --doc=HTML2 input.raku > output.html

```
The following regexen are applied to the contents of the RAKOPTS environment variable and if one or more matchd, they switch off the default rendering of the respective section:

>Regexen and Page Component

 | regex applied | if Match, then Turns off |
|:----:|:----:|
 | /:i 'no' '-'? 'toc' / | Table of Contents |
 | /:i 'no' '-'? 'meta' / | Meta information (eg AUTHOR) |
 | /:i 'no' '-'? 'glossary' / | Glossary |
 | /:i 'no' '-'? 'footnotes' / | Footnotes. |

Any or all of 'NoTOC' 'NoMETA' 'NoGloss' 'NoFoot' may be included in any order. Default is to include each section.

## Plugins options
Setting the Environment variable `PLUGINS` to a list of plugins will invoke only those plugins.

For example, if only the Graphviz plugin, and no other, is required, then use

```
PLUGINS='Graphviz' raku --doc=HTML2 input.raku > output.html

```
# Rakudoc-to-html
This is invoked on the command line as

```
Rakudoc-to-html input.rakudoc
```
The options are mostly like those for the compiler, and are:

*  --rakopts # like RAKOPTS

*  --plugins # like PLUGINS

*  --type # default is 'rakuclosure', see [templates](templates))

## Examples and plugins
`Rakudoc-to-html` can also be called to get an example Rakudoc file, and to get local versions of plugins.

```
Rakudoc-to-html Example
```
will bring in the default files and a document called `Samples.rakudoc`, which is then transformed to HTML.

```
Rakudoc-to-html get-local
```
will move the customisable (but not the core transfer plugins) to the local directory. Any sub-directory without a '_' in its name is considered a plugin (hence the name for the asset files directory `asset_files`).

Local plugins take precedence over default plugins.

# Defaults and customisation
The directory `$*HOME/.local/share/RenderPod` contains the following files:

*  html-templates-rakuclosure.raku # templates in Rakuclosure form to convert Rakudoc to HTML

*  html-templates-mustache.raku # ditto for mustache

*  html-templates-crotmp.raku # ditto for crotmp

*  simple-extras/ # plugin for simple additions to Rakudoc

*  graphviz/ # plugin to allow for graphviz files

*  latex-render/ # plugin to render math equations in Latex syntax to an image using a free on-line renderer.

*  styling/ # a customisable plugin containing the source for the css files and images for styling the Rakudoc html files. The plugin directory contains the following, which are transferred using `move-assets`.

	*  rakudoc-styling.css # the css to be associated with the HTML

	*  _highlight.scss # highlights source, used by next

	*  rakudoc-styling.scss # the scss source for the css file (this is not used by Pod::To::HTML2 but is included for ease of use). Converting scss to css can be found by internet searching. SASS is a good utility.

	*  favicon.ico # the favicon file

*  gather-js-jq/ # a special plugin for including js and jquery scripts in plugins. The plugin has a README, which provides more information about the various js/jq config keys.

*  gather-css/ # a special plugin for including css in plugins. The plugin has a README, which provides more information about the various css config keys.

*  move-assets/ # a core plugin for moving assets from another plugin to the `asset_files` sub-directory.

*  md-templates-rakuclosure.raku, etc. markdown files. They are not relevant for html rendering (see Pod::To::Markdown for more detail)

## Template file
A template file must contain the minimum number of templates (see [RenderPod](RenderPod.md) for more detail).

The template file must evaluate to a Raku **Associative** type, eg. Hash.

The `_templater` key (see one of the files for an example) defines which templating system is used.

The plugins are not guaranteed to have template systems other than `rakuclosure`. Template systems cannot be mixed.

# Plugins
A plugin is in a directory with the same name. A plugin name must start with a letter and contain any letter, number, or '-' characters. It may not contain a '_' after the first letter.

The following plugins are called by default, unless explicitly removed (by passing a plugins list without one or all of them):

*  simple-extras

*  graphviz

*  latex-render

Two special plugins are included in the defaults directory. Their contents are used by `Pod::To::HTML2` directly from the defaults directory. Copying them to a local directory will not have an effect. Its not a good idea to change them without reading the plugin documentation for the `Collection` module. They are:

*  gather-css

*  gather-js-jq

Each plugin contains a README file, which may provide more detail.

A plugin must contain

*  the file `config.raku`

*  files named in `config.raku`

*  The config **must** contain the following keys

	*  template-raku # can be an empty string, otherwise a file for templates

	*  custom-raku # can be an empty string, otherwise a file for custom blocks

*  The config **may** contain the following

	*  css # a file containing css, which will be merged into `rakudoc-extra.css`

	*  css-add # a file to be transfered to CWD

	*  css-link # a url for a style sheet

	*  js-script # this must be either a String, or point to a [string name, ordering] array.

	*  jquery # ditto

	*  js-link # ditto

	*  jquery-link # ditto

More information about the js/jquery keys can be found in `<defaults>/gather-s-q`

The file pointed to by the `template-raku` key is a raku program that evaluates to an Associative (eg., Hash) with keys pointing to templates. Plugins currently only use the `rakuclosure` system. More detail can be found in [RakuClosureTemplates](RakuClosureTemplates.md).

The file pointed to by the `custom-raku` key is a raku program that evaluates to a Positional (eg., Array). This is the list of names for the custom blocks. The templates should be the lower case names provided by the custom-raku list.

The default plugins provide examples.

# Standalone usage mixing Pod and code
'Standalone ... mixing' means that the program itself contains pod definitions (some examples are given below). This functionality is mainly for tests, but can be adapted to render other pod sources.

`Pod::To::HTML2` is a subclass of `PodProcessed`, which contains the code for a generic Pod Render. `Pod::To::HTML2` provides a default set of templates and minimal css (see [templates](templates)). It also exports some routines (not documented here) to pass the tests of the legacy `Pod::To::HTML2` module (see below for the rationale for choosing a different API).

`Pod::To::HTML2` also allows, as covered below, for a customised css file to be included, for individual template components to be changed on the fly, and also to provide a different set of templates.

What is happening in this case is that the raku compiler has compiled the Pod in the file, and the code then accesses the Pod segments. In fact the order of the Pod segments is irrelavant, but it is conventional to show Pod definitions interwoven with the code that accesses it.

```
use Pod::To::HTML2;
# for repeated pod trees to be output as a single page or html snippets (as in a test file)
my $renderer = Pod::To::HTML2.new(:name<Optional name defaults to UNNAMED>);
# later

=begin pod
some pod
=end pod

say 'The rendered pod is: ', $renderer.render-block( $=pod );

=begin pod

another fact-filled assertion

=end pod

say 'The next pod snippet is: ', $renderer.render-block( $=pod[1] );
# note that all the pod in a file is collected into a 'pod-tree', which is an array of pod blocks. Hence
# to obtain the last Pod block before a statement, as here, we need the latest addition to the pod tree.

# later and perhaps after many pod statements, each of which must be processed through pod-block

my $output-string = $renderer.source-wrap;

# will return an HTML string containing the body of all the pod items, TOC, Glossary and Footnotes.
# If there are headers in the accumulated pod, then a TOC will be generated and included
# if there are X<> type references in the accumulated pod, then a Glossary will be generated and included

$renderer.file-wrap(:output-file<some-useful-name>, :ext<html>);
# first .source-wrap is called and then output to a file.
# if ext is missing, 'html' is used
# if C<some-useful-name> is missing, C<name> is used, which defaults to C<UNNAMED>
# C<some-useful-name> could include a valid path.


```
# Custom blocks
The Rakudoc specification allows for Pod::Blocks to be named and meta data associated with it. This allows us to leverage the standard syntax to allow for non-standard blocks and templates.

Briefly, the name of the Block is placed in `html-blocks` (case is not important), and a template with the same name (**must** be lower case), is placed in the `html-templates-xxx.raku` file (the **xxx** depending on which templating system is used). Note, changes need only be made to the file with the templating system the user wants and specifies with the `--type` option.

In keeping with other named blocks, _Title_ case may be conventionally used for the block name and _Lower_ case is required for the template.

Some examples are provided in the default templates. They are

*  `Image` custom block and provides the `image` template. The actual images should be in the `assets/images` sub-directory. It is up to the user to do this.

*  `HR`. This adds a xxxish-dots class to `<hr> ` HTML elements.

*  `Quotation`. This formats content with an indentation, and adds both author and citation components.

*  `Latex-render`

*  `Graphviz`

## Latex-render
When an equation is given in a Latex syntax after a `Latex` block, the description of the equation is sent to an online renderer, and the image is inserted into the html. Eg.

```
    =for Latex
    \begin{align*}
    \sum_{i=1}^{k+1} i^{3}
    &= \biggl(\sum_{i=1}^{n} i^{3}\biggr) +  i^3\\
    &= \frac{k^{2}(k+1)^{2}}{4} + (k+1)^3 \\
    &= \frac{k^{2}(k+1)^{2} + 4(k+1)^3}{4}\\
    &= \frac{(k+1)^{2}(k^{2} + 4k + 4)}{4}\\
    &= \frac{(k+1)^{2}(k+2)^{2}}{4}
    \end{align*}


```
It is assumed that there is internet connectivity to the online engine.

# head

Graphviz

When a description of a digraph in the dot syntax is given between bracketing elements, then an image is generated in the html, eg.

```
    =begin Graphviz
        digraph G {
            main -> parse -> execute;
            main -> init;
            main -> cleanup;
            execute -> make_string;
            execute -> printf
            init -> make_string;
            main -> printf;
            execute -> compare;
        }
    =end Graphviz

```
The assumption is that the `dot` utility is installed.

More information on `dot` and `graphviz` can be found at [Graphviz](https://www.graphviz.org/)

The files <rakudoc-styling.css> and <favicon.ico> can be replaced completely. If they are present in the current directory, they will not be overwritten.

# Adding customisation programmatically
Suppose we wish to have a diagram block with a source and to assign classes to it. We want the HTML container to be `figure`.

In the Rakudoc source code, we would have:

```
    =for diagram :src<https://someplace.nice/fabulous.png> :class<float left>
    This is the caption.

```
Note that the `for` takes configuration parameters to be fed to the template, and ends at the first blank line or next `Pod::Block`, that is a line begining with `=`.

Then in the rendering program we need to provide to the `ProcessedPod` class the new object name, and the corresponding template (in **this** example, the `Mustache` system is used, which means all the other templates must be in `Mustache`).

The Block name and template must be the same name. Thus we would have:

```
    use v6;
    use Pod::To::HTML2;
    my Pod::To::HTML2 $r .= new;
    $r.custom = <diagram>;
    $r.modify-templates( %( diagram => '<figure source="{{ src }}" class="{{ class }}">{{ contents }}</figure>' , ) );

```
# Highlighting
Generally it is desirable to highlight code contained in `=code ` blocks. While perhaps this may be done in-Browser, it can be done at HTML generation, via the Templates and a highlighter function.

This distribution, `Raku::Pod::Render`, by default sets up the atom-highlighter stack (installation dependencies can be found in [README](README.md)).

Since highlighting generates considerably more HTML, it is turned off by default, which will affect the `--doc=HTML ` compiler option.

Highlighting is handled in the Templates. The default Templates use the atom-highlighter, which is installed with `Raku::Pod::Render` by default.

Highlighting is enabled at the time of HTML generation by setting `$render.highlight-code=True` after `Pod::To::HTML2` object instantiation.

Another highlighter could be attached to a Pod::To::HTML2 object, in which case the following need to be done:

*  the getter and setter functions of `.highlight-code` need to be over-ridden so as to set up the code, and turn it off

*  a closure needs to be assigned to `.highlight `. The closure should accept a Str and highlight it.

*  the `Pod::To::HTML2` object has an attribut `.atom-highlighter` of type `Proc` to hold an external function.

The `atom-highlighter` automatically escapes HTML entities, but so does `GenericPod`. Consequently, if a different highlighter is used for highlighting when HTML is generated, escaping needs to be turned off within GenericPod for Pod::Code blocks. This is the default behaviour. If a different behaviour is required, then `no-code-escape` needs to be set to False.

# Templates
The default templating system is a hash of Raku closures. More about templates can be found in [RenderPod](RenderPod.md). Another template engine is Template::Mustache. This can be accessed as `use Pod::To::HTML2::Mustache`. A minimal default set of templates is provided with the Module.

Each template can be changed using the `modify-templates` method. Be careful when over-riding `head-block` to ensure the css is properly referenced.

A full set of new templates can be provided to ProcessedPod either by providing a path/filename to the processor method, eg.,

```
use Pod::To::HTML2;
my Pod::To::HTML2 $p .= new;

$p.templates<path/to/mytemplates.raku>;

# or if all templates known

$p.templates( %( format-b => '<b>{{ contents }}</b>' .... ) );


```
If :templates is given a string, then it expects a file that can be compiled by raku and evaluates to a Hash containing the templates. More about the hash can be found in [RenderPod](renderpod.md).

# Exported Subroutines
Two functions are exported to provide backwards compatibility with legacy Pod::To::HTML module. They map onto the methods described in `PodRender`.

Only those options actually tested will be supported.

*  node2html

```
sub node2html( $pod ) is export
```
*  pod2html

```
sub pod2html( $pod, *%options ) is export
```
# Why Reinvent the Wheel?
The two original Pod rendering modules are `Pod::To::HTML2 ` (later **legacy P2HTML** ) and `Pod::To::BigPage `. So why rewrite the modules and create another API? There was an attempt to rewrite the existing modules, but the problems go deeper than a rewrite. The following difficulties can be found with the legacy Modules:

*  Inside the code of legacy P2HTML there were several comments such as 'fix me'. The API provided a number of functions with different parameters that are not documented.

*  Not all of the API is tested.

*  One or two POD features are not implemented in legacy P2HTML, but are implemented in P2BigPage.

*  Fundamentally: HTML snippets for different Pod Blocks is hard-coded into the software. Changing the structure of the HTML requires rewriting the software.

*  Neither module deals with Indexes, or Glossaries. POD6 defines the ** ** format code to place text in a glossary (or index), but this information is not collected or used by P2HTML. The Table of Content data is not collected in the same pass through the document as the generation of the HTML code.

This module deal with these problems as follows:



*  All Pod Blocks are associated with templates and data for the templates. So the Generic Renderer passes off generation of the output format to a Template engine. (Currently, only the Template::Mustache engine is supported, but the code has been designed to allow for other template engines to be supported by over-ridding only the template rendering methods).

*  Data for **Page Components** such as `Table of Contents`, `Glossary`, `Footnotes`, and `MetaData` are collected in a single processing pass of the Generic Renderer. The subclass can provide templates for the whole document to incorporate the Page Components as desired.

*  All the links (both external and internal) are collected together and can be accessed after processing the Pod source, thus allowing for testing of the links separately.

*  There is a clear distinction between what is needed for a particular output format, eg., HTML or MarkDown, and what is needed to render Pod. Thus, HTML requires css and headers, etc. MarkDown requires the anchors to connect a Table of Contents to specific Headers in the text to be written in a specific way.





----
Rendered from Pod2HTML2 at 2022-12-12T21:37:17Z