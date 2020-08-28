# Rendering Pod Distribution
>A generic distribution to render Pod in a file (program or module) or in a cache (eg. the Raku documentation collection)


----
## Table of Contents
[Creating a Renderer](#creating-a-renderer)  
[Pod Source Configuration](#pod-source-configuration)  
[Templates](#templates)  
[String Template](#string-template)  
[Block Templates](#block-templates)  
[Partials and New Templates](#partials-and-new-templates)  
[Handling Declarator blocks](#handling-declarator-blocks)  
[Change the Templating Engine](#change-the-templating-engine)  
[Raku Closure Templates](#raku-closure-templates)  
[Customised Pod and Templates](#customised-pod-and-templates)  
[Custom Pod Block](#custom-pod-block)  
[Para](#para)  
[Custom Format Code](#custom-format-code)  
[Rendering Strategy](#rendering-strategy)  
[Rendering many Pod Sources](#rendering-many-pod-sources)  
[Methods Provided by ProcessedPod](#methods-provided-by-processedpod)  
[modify-templates](#modify-templates)  
[rewrite-target](#rewrite-target)  
[process-pod](#process-pod)  
[render-block](#render-block)  
[render-tree](#render-tree)  
[emit-and-renew-processed-state](#emit-and-renew-processed-state)  
[file-wrap](#file-wrap)  
[source-wrap](#source-wrap)  
[Individual component renderers](#individual-component-renderers)  
[Public Class Attributes](#public-class-attributes)  
[ExtractPod](#extractpod)  
[Templates](#templates)  

----
This distribution ('distribution' because it contains several modules and other resources) provides a generic class `ProcessedPod`, which accepts templates, and renders one or more Pod trees. The class collects the information in the Pod files to create page components, such as _Table of Contents_, _Glossary_, _Metadata_ (eg. Author, version, etc), and _Footnotes_.

The output depends entirely on the templates. The body of the text, TOC, Glossary, and Footnotes can be output or suppressed, and their position can be controlled using a combination of templates, or in the case of HTML, templates and CSS. It also means that the same generic class can be used for HTML and MarkDown.

Two other modules are provided: `Pod::To::HTML` and `Pod::To::MarkDown`. For more information on them, see [Pod::To::HTML](Pod2HTML.md). These have the functionality and default templates to be used in conjunction with the **raku** (aka perl6) compiler option `--doc=name`.

The aim of ProcessedPod is to allow for a more flexible mechanism for rendering POD. For example, when multiple POD6 files are combined each individual source generates TOC, Glossary, Footnotes, and Metadata information. There is no single way these can be combined, and different uses will need a different approach. For example, a flat-file HTML page will need separate pages for each source, with a landing page and global TOC and glossary pages to link them all.

The `Pod::To::HTML` has a simple way of handling customised CSS, but no way to access embedded images other than svg files. Modifying the templates, when there is information about the serving environment, can change this.

This module uses BOTH a new RakuCustomTemplater and the Moustache templating system at `Template::Mustache`. The templating engine is chosen automatically depending on the templates provided. A custom template engine can also be added.

# Creating a Renderer
The first step in rendering is to create a renderer.

The renderer needs to take into account the output format, eg., html, incorporate non-default templates (eg., a designer may want to have customised classes in paragraphs or headers). The Pod renderer requires templates for a number of document elements, see TEMPLATES below.

Essentially, a hash of element keys pointing to Mustache strings is provided to the renderer. The `Pod::To::HTML` and `Pod::To::MarkDown` modules in this distribution provide default templates to the `ProcessedPod` class.

The renderer can be customised on-the-fly by modifying the keys of the template hash. For example, (using a Mustache template)

```
    use RenderPod;
    my $renderer .= RenderPod.new;
    $renderer.modify-templates( %(format-b =>
        '<strong class="myStrongClass {{# addClass }}{{ addClass }}{{/ addClass }}">{{{ contents }}}</strong>')
    );
    # The default template is something like
    #       'format-b' => '<strong{{# addClass }} class="{{ addClass }}"{{/ addClass }}>{{{ contents }}}</strong>'
    # the effect of this change is to add myStrongClass to all instances of B<> including any extra classes added by the POD

```
This would be wanted if a different rendering of bold is needed in some source file, or a page component. Bear in mind that for HTML, it is probably better to add another css class to a specific paragraph (for example) using the Pod config metadata. This is picked up by ProcessedPod (as can be seen in the above example where `addClass` is used to add an extra class to the `<strong> ` container.

# Pod Source Configuration
Most Pod source files will begin with `=begin pod`. Any line with `=begin xxx` may have configuration data, eg.

```
    =begin pod :kind<Language> :subkind<Language> :class<Major text>
    ...

```
The first `=begin pod` to be rendered after initiation, or after the `.emit-and-renew-processed-state` method, will have its configuration data transferred to the `ProcessedPod` object's `%.pod-config-data` attribute.

When multiple files are rendered, any meta data associated with the pod can be accessed during the Rendering Iteration.

# Templates
The nature of the templates and their interpretation depends on the `rendition` method, which must be over-ridden for a different templating engine. See [Change the Templating Engine](#change-the-templating-engine).

More about Templates can be found in [RakuClosureTemplates](RakuClosureTemplates.md).

When a ProcessPod instance is instantiated, a templating object xxxx can be passed via the `:templates` parameter, eg.

```
my $p = ProcessedPod.new;
$p.templates(:templates( xxxx ) );

```
If the object is a Hash, then it is considered a Hash of the templates, and verified for completeness.

If the object is a String, then it is considered a `path/filename` to a file containing a Raku program that evaluates to a Hash, which is then verified as a Hash of templates.

Each entry in the template Hash depends on the Template Engine. The following notes are for the MustacheTemplater. The Hash structure for the default RakuClosureTemplater can be found in [Raku Closure Templater](RakuClosureTemplates.md).

## String Template
For example if `'escaped' =` '{{ contents }}', > is a line in a hash declaration of the templates, then the right hand side is the `Mustache` template for the `escaped` key. The template engine is called with a hash containing String data that are interpolated into the template. `contents` is provided for all keys, but some keys have more complex data.

## Block Templates
`Mustache` by design is not intended to have any logic, although it does allow lambdas. Since the latter are not well documented and some template-specific preprocessing is required, or the default action of the Templating engine needs to be over-ridden, extra functionality is provided.

Instead of a plain text template being associated with a Template Hash key, the key can be associated with a block that can pre-process the data provided to the Mustache engine, or change the template. The block must return a String with a valid Mustache template.

For example,

```
'escaped' => -> %params { %params<contents>.subst-mutate(/\'/, '&39;', :g ); '{{ contents }}' }


```
The block is called with a Hash parameter that is assigned to `%params`. The `contents` key of `%params`) is adjusted because `Mustache` does not escape single-quotes.

## Partials and New Templates
Mustache allows for other templates to be used as partials. Thus it is possible to create new templates that use the templates needed by ProcessedPod and incorporate them in output templates.

For example:

```
$p.modify-templates( %(:newone(
    '<container>{{ contents }}</container>'
    ),
    :format-b('{{> newone }}'))
);


```
Now the pod line `This is some B<boldish text> in a line` will result in

```
<p>This is some <container>boldish text</container> in a line</p>
```
# Handling Declarator blocks
Currently POD6 that starts with `|#` or `#=` next to a declaration are not handled consistently or correctly. Declarator comments only work when associated with `Routine` declarations, such as `sub` or `method`. Declarator comments associated with variables are concatenated by the compiler with the next `Routine` declaration.

`GenericPod` passes out the declaration code as `:code` and the associated content as <:contents>. It also **adds** the code to the `Glossary` page component, generating a `:target` for the link back.

# Change the Templating Engine
The default system now is RakuClosureTemplates. The Mustache templater is also used. The choice is done automaticallt: if the templates supplied to the ProcessedPod object is Mustache, then the Mustache templater is used, otherwise the RakuClosureTemplater is used.

In order to change the Templating Engine, a Templater Role needs to be created using the `SetupTemplates` and `RakuClosureTemplates` or `MustacheTemplater` roles in this distribution as a model. Then a new class similar to ProcessedPod can be created as

```
class NewProcessedPod is GenericPod does myNewTemplater {}
```
The new role may only need to over-ride `method rendition( Str $key, Hash %params --` Str )>.

Assuming that the templating engine is NewTemplateEngine, and that - like Template::Mustache - it is instantiates with `.new`, and has a `.render` method which takes a String template, and Hash of strings to interpolate, and which returns a String, viz `.render( Str $string, Hash %params, :from( %hash-of-templates) --` Str )>.

## Raku Closure Templates
This system was introduced to speed up processing. The Pod Rendering engine generates a set of keys and parameters. It calls the method `rendition` with the key and the parameters, and expects a string back with the parameters interpolated into the output.

In addition, templates may call templates. With the exception of the key 'escaped', which expects a string only, all the other templates expect the signature `( %prm, %tml? )`. `%prm` contains the parameters to be interpolated, `%tml` is the array of templates.

Each template MUST return string, which may be ''.

# Customised Pod and Templates
The POD6 specification is sufficiently generic to allow for some easy customisations, and the `Pod::To::HTML` renderer in this distribution passes the associated meta data on to the template. This allows for the customisation of Pod::Blocks and Format Codes.

## Custom Pod Block
Standard Pod allows for Pod::Blocks to be **named** and configuration data provided. This allows us to leverage the standard syntax to allow for non-standard blocks and templates.

If a class needs to be added to Pod Block, say a specific paragraph, then the following can be put in a pod file

# para

Paragraph texts

The 'para' template needs to be changed (either on the fly or at instantiation)

para => '<p{{# class }} class="{{ class }}">{{{ contents }}</p>'

A completely new block can be created. For example, the HTML module adds the `Image` custom block by default, and provides the `image` template.

In keeping with other named blocks, _Title_ case may be conventionally used for the block name but _Lower_ case is required for the template. Note the _Upper_ case (all letters) is reserved for descriptors that are added (in HTML) as meta data.

Suppose we wish to have a diagram block with a source and to assign classes to it. We want the HTML container to be `figure`.

In the pod source code, we would have:

```
    =for diagram :src<https://someplace.nice/fabulous.png> :class<float left>
    This is the caption.

```
Note that the `for` takes configuration parameters to be fed to the template, and ends at the first blank line or next `pod` instruction.

Then in the rendering program we need to provide to ProcessedPod the new object name, and the corresponding template. These must be the same name. Thus we would have:

```
    use v6;
    use Pod::To::HTML;
    my Pod::To::HTML $r .= new;
    $r.custom = <diagram>;
    $r.modify-templates( %( diagram => '<figure source="{{ src }}" class="{{ class }}">{{ contents }}</figure>' , ) );

```
## Custom Format Code
This is even easier to handle as all that is needed is to supply a template in the form `format-ß` where **ß** is a unicode character other than **B C E I K L N P T U V X Z**, which are defined in the Pod6 specification.

If the `Pod::To::HTML` renderer in this distribution comes across a Format Code letter, it will check the templates it has, and if one of the form `format-ß` exists, then it will call the template with the enclosed text as `contents`.

For example, lets assume that we want a Format Code to access the [Font Awesome Icons](https://fontawesome.com/v4.7.0/icons). The template will need to be defined as follows (assuming the Mustache templater):

```
$r.modify-templates( %( :format-f( '<i class="fa {{{ contents }}}"></i>' ) ));
```
And the pod text would include something like "this text has a F<fa-snowflake-o> icon" in it. Note that although the HTML will be rendered correctly, it will also be necessary to ensure that the `head-block` template is altered so that the `Font Awesome` Javascript library is included.

# Rendering Strategy
A rendering strategy is required for a complex task consisting of many Pod sources. A rendering strategy has to consider:

*  The pod contained in a single file may be provided as one or more trees of Pod blocks. A pod tree may contain blocks to be referred to in a Table of Contents (TOC), and also it may contain anchors to which other documentation may point. This means that the pod in each separate file will automatically produces its own TOC (a list of headers in the order in which they appear in the pod tree(s), and its own Glossary (a list of terms that are encountered, perhaps multiple times for each term, within the text).

*  When only a single file source is used (such as when a Pod::To::name is called by the compiler), then the content, TOC and glossary have to be rendered together.

*  Multiple pod files will by definition exist in a collection that should be rendered together in a consistent manner. The content from a single source file will be called a **Component**. This will be handled in another module raku-render-collection There have to be the following facilities

*  A strategy to create one or more TOC's for the whole collection that collect and combine all the **Component** TOC's. The intent is to allow for TOCs that are designed and do not follow the alphabetical name of the **Component** source, together with a default alphabetical list.

*  A strategy to create one or more Glossary(ies) from all the **Component** glossaries

# Rendering many Pod Sources
A complete render strategy has to deal with multiple page components.

The following sketches the use of the `Pod::To::HTML` class.

For example, suppose we want to render each POD source file as a separate html file, and combine the global page components separately.

The the `ProcessedPob` object expects a compiled Pod object. One way to do this is use the `Pod::From::Cache` module.

```
    use Pod::To::HTML;
    my $p = Pod::To::HTML.new;
    my %pod-input; # key is the path-name for the output file, value is a Pod::Block
    my @processed;

    #
    # ... populate @pod-input, eg from a document cache, or use EVALFILE on each source
    #

    my $counter = 1; # a counter to illustrate how to change output file name

    for %pod-input.kv -> $nm, $pd {
        with $p { # topicalises the processor
            .name = $nm;
            # change templates on a per file basis before calling process-pod,
            # to be used with care because it forces a recache of the templates, which is slow
            # also, the templates probably need to be returned to normal (not shown here), again requiring a recache
            if $nm ~~ /^ 'Class' /
            {
                .replace-template( %(
                    format-b => '<strong class="myStrongClass {{# addClass }}{{ addClass }}{{/ addClass }}">{{{ contents }}}</strong>'
                    # was 'format-b' => '<strong{{# addClass }} class="{{ addClass }}"{{/ addClass }}>{{{ contents }}}</strong>'
                    # the effect of this change is to add myStrongClass to all instances of B<> including any extra classes added by the POD
                ))
            }
            .process-pod( $pd );
            # change output name from $nm if necessary
            .file-wrap( "{ $counter++ }_$nm" );
            # get the pod structure, delete the information to continue with a new pod tree, retain the cached templates
            @processed.append: $p.emit-and-renew-processed-state; # beware, pod-structure also deletes body, toc, glossary, etc contents
        }
    }
    # each instance of @processed will have TOC, Glossary and Footnote arrays that can be combined in some way
    for @processed {
        # each file has been written, but now process the collection page component data and write the files for all the collection
    }
    # code to write global TOC and Glossary html files.

```
# Methods Provided by ProcessedPod
## modify-templates
```
method modify-templates( %new-templates )
```
Allows for templates to be modified or new ones added before or during pod processing.

**Note:** Since the templating engine needs to be reinitialised in order to clear a template cache, it is probably not efficient to modify templates too many times during processing.

`modify-templates` **replaces** the keys in the `%new-templates` hash. It will add new keys to the internal template store.

Example:

```
use PodRender;
my PodRender $p .= new;
$p.templates( 'path/to/newtemplates.raku');
$p.replace-template( %(
                    format-b => '<strong class="myStrongClass {{# addClass }}{{ addClass }}{{/ addClass }}">{{{ contents }}}</strong>'
                    # was 'format-b' => '<strong{{# addClass }} class="{{ addClass }}"{{/ addClass }}>{{{ contents }}}</strong>'
                    # the effect of this change is to add myStrongClass to all instances of B<> including any extra classes added by the POD
                ))

```
## rewrite-target
This method may need to be over-ridden, eg., for MarkDown which uses a different targetting function.

```
method rewrite-target(Str $candidate-name is copy, :$unique --> Str )
```
Rewrites targets (link destinations) to be made unique and to be cannonised depending on the output format. Takes the candidate name and whether it should be unique, returns with the cannonised link name Target names inside the POD file, eg., headers, glossary, footnotes The function is called to cannonise the target name and to ensure - if necessary - that the target name used in the link is unique. The following method uses an algorithm designed to pass the legacy `Pod::To::HTML` tests.

When indexing a unique target is needed even when same entry is repeated When a Heading is a target, the reference must come from the name

```
method rewrite-target(Str $candidate-name is copy, :$unique --> Str) {
        return $!default-top if $candidate-name eq $!default-top;
        # don't rewrite the top

        $candidate-name = $candidate-name.subst(/\s+/, '_', :g);
        if $unique {
            $candidate-name ~= '_0' if $candidate-name (<) $!targets;
            ++$candidate-name while $!targets{$candidate-name};
            # will continue to loop until a unique name is found
        }
        $!targets{$candidate-name}++;
        # now add to targets, no effect if not unique
        $candidate-name
    }

```
## process-pod
```
method process-pod( $pod ) {
```
Process the pod block or tree passed to it, and concatenates it to previous pod tree. Returns a string representation of the tree in the required format

## render-block
```
method render-block( $pod )
```
Renders a pod tree, but probably a block Returns only the pod that was passed

## render-tree
```
method render-tree( $pod )
```
Tenders the whole pod tree Is actually an alias to process-pod

## emit-and-renew-processed-state
```
method emit-and-renew-processed-state
```
Deletes any previously processed pod, keeping the template engine cache Returns the pod-structure deleted as a Hash, for storage in an array when multiple files are processed.

## file-wrap
```
method file-wrap(:$filename = $.name, :$ext = 'html' )
```
Saves the rendered pod tree as a file, and its document structures, uses source wrap Filename defaults to the name of the pod tree, and ext defaults to html

## source-wrap
```
method source-wrap( --> Str )
```
Renders all of the document structures, and wraps them and the body Uses the source-wrap template

## Individual component renderers
The following are called by `source-wrap` but could be called separately, eg., if a different textual template such as `format-b` should be used inside the component.

*  method render-toc( --> Str )

*  method render-glossary(-->Str)

*  method render-footnotes(--> Str)

*  method render-meta(--> Str)

# Public Class Attributes
```
# provided at instantiation or by attributes on Class instance
has $.front-matter is rw = 'preface'; # Text between =TITLE and first header, this is used to refer for textual placenames
has Str $.name is rw;
has Str $.title is rw = $!name;
has Str $.subtitle is rw = '';
has Str $.path is rw; # should be path of original document, defaults to $.name
has Str $.top is rw = $!default-top; # defaults to top, then becomes target for TITLE
has &.highlighter is rw; # a callable (eg. provided by external program) that converts [html] to highlighted raku code

# document level information
has $.lang is rw = 'en'; # language of pod file

# Output rendering information
has Bool $.no-meta is rw = False; # set to True eliminates meta data rendering
has Bool $.no-footnotes is rw = False; # set to True eliminates rendering of footnotes
has Bool $.no-toc is rw = False; # set to True to exclude TOC even if there are headers
has Bool $.no-glossary is rw = False; # set to True to exclude Glossary even if there are internal anchors

# debugging
has Bool $.debug is rw; # outputs to STDERR information on processing
has Bool $.verbose is rw; # outputs to STDERR more detail about errors.

# Structure to collect links, eg. to test whether they all work
```
# ExtractPod
This is a helper module that provides a version of `load` instead of the file load version of Pod::Load.

# Templates
More information can be found in [PodTemplates](PodTemplates.md)

There is a minimum set of templates that must be provided for a Pod file to be rendered. These are:

```
    < block-code comment declarator defn dlist-end dlist-start escaped footnotes format-b format-c
        format-i format-k format-l format-n format-p format-r format-t format-u format-x glossary heading
        item list meta named output para pod raw source-wrap table toc >

```
When the `.templates` method is called, the templates will be checked against this list for completeness. An Exception will be thrown if all the templates are not provided. Extra templates can be included. `Pod::To::HTML` uses this to have partial templates that use the required templates.








----
Rendered from RenderPod at 2020-08-28T23:43:25Z