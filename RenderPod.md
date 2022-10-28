# Rendering Pod Distribution
>A generic distribution to render Pod in a file (program or module) or in a cache (eg. the Raku documentation collection). The module allows for user defined pod-blocks, user defined rendering templates, and user defined plugins that provide custom pod blocks, templates, and external data.


## Table of Contents
[Creating a Renderer](#creating-a-renderer)  
[Pod Source Configuration](#pod-source-configuration)  
[Templates](#templates)  
[New Templates](#new-templates)  
[Additional Templates](#additional-templates)  
[Raku Closure Templates](#raku-closure-templates)  
[Mustache Templates - minor extension.](#mustache-templates---minor-extension)  
[String Template](#string-template)  
[Block Templates](#block-templates)  
[Partials and New Templates](#partials-and-new-templates)  
[Debugging](#debugging)  
[Handling Declarator blocks](#handling-declarator-blocks)  
[Change the Templating Engine](#change-the-templating-engine)  
[Customised Pod and Templates](#customised-pod-and-templates)  
[Custom Pod Block](#custom-pod-block)  
[Plugin config data](#plugin-config-data)  
[Table of Contents](#table-of-contents)  
[Custom Format Code](#custom-format-code)  
[Plugins](#plugins)  
[External Data](#external-data)  
[Rendering Strategy](#rendering-strategy)  
[Rendering many Pod Sources](#rendering-many-pod-sources)  
[Methods Provided by ProcessedPod](#methods-provided-by-processedpod)  
[modify-templates](#modify-templates)  
[rewrite-target](#rewrite-target)  
[add-plugin](#add-plugin)  
[add-custom( $block )](#add-custom-block-)  
[add-templates( $template )](#add-templates-template-)  
[add-data( $name-space, $object )](#add-data-name-space-object-)  
[get-data( $name-space )](#get-data-name-space-)  
[process-pod](#process-pod)  
[render-block](#render-block)  
[render-tree](#render-tree)  
[emit-and-renew-processed-state](#emit-and-renew-processed-state)  
[file-wrap](#file-wrap)  
[source-wrap](#source-wrap)  
[Individual component renderers](#individual-component-renderers)  
[Public Class Attributes](#public-class-attributes)  
[Templates](#templates)  

----
This distribution ('distribution' because it contains several modules and other resources) provides a generic class `ProcessedPod`, which accepts templates, and renders one or more Pod trees. The class collects the information in the Pod files to create page components, such as _Table of Contents_, _Glossary_, _Metadata_ (eg. Author, version, etc), and _Footnotes_.

The output depends entirely on the templates. Absolutely no output rendering is performed in the module that processes the POD6 files. The body of the text, TOC, Glossary, and Footnotes can be output or suppressed, and their position can be controlled using a combination of templates, or in the case of HTML, templates and CSS. It also means that the same generic class can be used for HTML and MarkDown, or any other output format such as epub.

Two other modules are provided: `Pod::To::HTML2` and `Pod::To::MarkDown`. For more information on them, see [Pod::To::HTML2](Pod2HTML2.md). These have the functionality and default templates to be used in conjunction with the **raku** (aka perl6) compiler option `--doc=name`. Eg:

```
raku --doc=HTML2 a-raku-program-with-rakudoc-content.raku
```
ProcessedPod has also been designed to allow for rendering multiple Rakudoc (POD6) files. In this case, the components collected from individual source, such as TOC, Glossary, Footnotes, and Metadata information, need to be combined. However, a user will want to have pages dedicated to the whole collection of sources, with the content of these collection pages described using Rakudoc (POD6), which will require customised pod and associated templates, but also the templates will need to have data provided from an external source (eg. the collective TOC). This functionality can be added via plugins.

The `Pod::To::HTML2` module has a simple way of handling customised CSS, but no way to access embedded images other than svg files. Modifying the templates, when there is information about the serving environment, can change this.

This module uses BOTH a new Template system `Raku-Closure-Templates` and the Moustache templating system `Template::Mustache`. ProcessedPod choses the templating engine is automatically depending on how the template for Bold-face is provided. A different custom template engine can also be added.

# Creating a Renderer
The first step in rendering is to create a renderer.

The renderer needs to take into account the output format, eg., html, incorporate non-default templates (eg., a designer may want to have customised classes in paragraphs or headers). The Pod renderer requires templates for a number of document elements, see TEMPLATES below.

Essentially, a hash of element keys pointing to Mustache strings is provided to the renderer. The `Pod::To::HTML2` and `Pod::To::MarkDown` modules in this distribution provide default templates to the `ProcessedPod` class.

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

The rendering of page components can be explicitly turned off by setting `no-toc`, `no-glossary`, `no-footnotes`, or `no-meta` in the config of pod. eg

```
    =begin pod :no-glossary


```
# Templates
Rakudoc (POD6) files contain both content and hints about how to render the content. The aim of this module is to separate the output completely from processing the Rakudoc (POD6).

Both a new Raku-Closure-Template system (see [RakuClosureTemplates](RakuClosureTemplates.md)) and the Template::Mustache system can be used. Essentially Raku-Closure-Templates are Raku `subs` which are compiled by Raku and the run to generate a string.

Another templating engine can be added, See [Change the Templating Engine](#change-the-templating-engine).

## New Templates
When a ProcessPod instance is instantiated, a templating object xxxx can be passed via the `:templates` parameter, eg.

```
my $p = ProcessedPod.new;
$p.templates(:templates( xxxx ) );

```
If the object is a Hash, then it is considered a Hash of all the required templates, and verified for completeness.

If the object is a String, then it is considered a `path/filename` to a file containing a Raku program that evaluates to a Hash, which is then verified as a Hash of all the required templates.

The format of the value assigned to each key in the template Hash depends on the Template Engine.

The format difference allows for `ProcessedPod` to choose which Templating Engine to use.

## Additional Templates
Additional templates can be added to the existing templates. The templates are added in the same way as new templates, but no check is made to ensure that the additional templates are the same as the initial ones. Mixing templates will cause an Exception to be thrown when a new template is first used.

```
my $p = ProcessedPod.new;
# some time later in the program
$p.modify-templates(:templates( xxxx ) );

```
`xxxx` may be a Hash or a Str, in which case it is taken to be a path to a Raku program that evaluates to a Hash.

The keys of the (resultant) Hash are added to the existing templates. Any previously existing templates are over-ridden.

## Raku Closure Templates
This system was introduced to speed up processing. The Pod Rendering engine generates a set of keys and parameters. It calls the method `rendition` with the key and the parameters, and expects a string back with the parameters interpolated into the output.

In addition, templates may call templates. With the exception of the key 'escaped', which expects a string only, all the other templates expect the signature `( %prm, %tml? )`. `%prm` contains the parameters to be interpolated, `%tml` is the array of templates.

Each template MUST return string, which may be ''.

## Mustache Templates - minor extension.
The following notes are for the MustacheTemplater, because an extension of Mustache templates is used here.

The Hash structure for the default RakuClosureTemplater can be found in [Raku Closure Templater](RakuClosureTemplates.md).

### String Template
For example if `'escaped' =` '{{ contents }}', > is a line in a hash declaration of the templates, then the right hand side is the `Mustache` template for the `escaped` key. The template engine is called with a hash containing String data that are interpolated into the template. `contents` is provided for all keys, but some keys have more complex data.

### Block Templates
`Mustache` by design is not intended to have any logic, although it does allow lambdas. Since the latter are not well documented and some template-specific preprocessing is required, or the default action of the Templating engine needs to be over-ridden, extra functionality is provided.

Instead of a plain text template being associated with a Template Hash key, the key can be associated with a block that can pre-process the data provided to the Mustache engine, or change the template. The block must return a String with a valid Mustache template.

For example,

```
'escaped' => -> %params { %params<contents>.subst-mutate(/\'/, '&39;', :g ); '{{ contents }}' }


```
The block is called with a Hash parameter that is assigned to `%params`. The `contents` key of `%params`) is adjusted because `Mustache` does not escape single-quotes.

### Partials and New Templates
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
# Debugging
The processing stages can be followed by setting `:debug` and/or `:verbose`, eg

```
$p.debug = True;
```
`:verbose` has no effect without `:debug`

Debug causes information to be produced in each Block Handle, so will be triggered for each `Pod::Block`

Verbose causes information to be produced by the template handler and rendering subs.

# Handling Declarator blocks
Currently Rakudoc (POD6) that starts with `|#` or `#=` next to a declaration are not handled consistently or correctly. Declarator comments only work when associated with `Routine` declarations, such as `sub` or `method`. Declarator comments associated with variables are concatenated by the compiler with the next `Routine` declaration.

`GenericPod` passes out the declaration code as `:code` and the associated content as <:contents>. It also **adds** the code to the `Glossary` page component, generating a `:target` for the link back.

# Change the Templating Engine
The default system now is RakuClosureTemplates. The Mustache templater is also used. The choice is done automaticallt: if the templates supplied to the ProcessedPod object is Mustache, then the Mustache templater is used, otherwise the RakuClosureTemplater is used.

In order to change the Templating Engine, a Templater Role needs to be created using the `SetupTemplates` and `RakuClosureTemplates` or `MustacheTemplater` roles in this distribution as a model. Then a new class similar to ProcessedPod can be created as

```
class NewProcessedPod is GenericPod does myNewTemplater {}
```
The new role may only need to over-ride `method rendition( Str $key, Hash %params --` Str )>.

Assuming that the templating engine is NewTemplateEngine, and that - like Template::Mustache - it is instantiates with `.new`, and has a `.render` method which takes a String template, and Hash of strings to interpolate, and which returns a String, viz `.render( Str $string, Hash %params, :from( %hash-of-templates) --` Str )>.

# Customised Pod and Templates
The Rakudoc (POD6) specification is sufficiently generic to allow for some easy customisations, and the `Pod::To::HTML2` renderer in this distribution passes the associated meta data on to the template. This allows for the customisation of Pod::Blocks and Format Codes.

## Custom Pod Block
Standard Pod allows for Pod::Blocks to be **named** and configuration data provided. This allows us to leverage the standard syntax to allow for non-standard blocks and templates.

If a class needs to be added to Pod Block, say a specific paragraph, then the following can be put in a pod file

```
    =begin para :class<float right>
        Paragraph texts
    =end para

```
Suppose the 'para' template needs to be changed (either on the fly or at instantiation)

```
para => '<p{{# class }} class="{{ class }}">{{{ contents }}</p>'
```
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
    use Pod::To::HTML2;
    my Pod::To::HTML2 $r .= new;
    $r.add-custom: <diagram>;
    $r.modify-templates( %( diagram => '<figure source="{{ src }}" class="{{ class }}">{{ contents }}</figure>' , ) );

```
It is possible to cause a Custom block to use another template by using the template configuration eg.,

```
    =for object :template<diagram-float-left>
        Something here

    =for object
        Something else


```
In this case the first `object` is rendered with the template `diagram-float-left`, which must exist in the templates Hash, and the second time `object` is rendered with the default template `object`, which also must exist.

The ability to specify another template for rendering applies to most `Pod::Block::Named`, except for the reserved `TITLE`, `SUBTILE` etc. Care needs to be taken to ensure the template specified can handle the parameters it is given.

Pod Blocks that have been added as custom provide some extra functionality in order to aid plugin development.

### Plugin config data
When a [plugin is added](Plugins.md) the configuration data of the plugin is added to the `ProcessedPod` object, and that data is provided to the template when a custom block is rendered.

The data is added as a key to the parameters passed to the Template with the name of the customised block in lower-case, or as a key with the name set by the `name-space` configuration.

### Table of Contents
The Customised block's contents are added to the Table of Contents, by default at level 1. This equates a customised plugin block to a `=head1` pod block.

If the block's config parameters include the key `headlevel`, then that level is used instead of 1. For example,

```
    =for ListFiles :headlevel<2>
    Some caption text


```
would include `Some caption text` in the TOC as if it were the contents of a `=head2` block.

Setting `:headlevel<0> ` will not register the block at all.

The parameters passed to the template will also contain a `:target` key, which can be used to provide an anchor, so that when the item in the TOC is clicked (assuming HTML output), the window is moved to the start of the relevant content.

It is for the template to use the target appropriately.

## Custom Format Code
This is even easier to handle as all that is needed is to supply a template in the form `format-ß` where **ß** is a unicode character other than the standard codes, viz., **B C E I K L N P T U V X Z**, which are defined in the Rakudoc (POD6) specification. Several of the standard codes, such as **L** and **X**, parse the contents, placing all data after `|` in the meta container, and if separated by `;`, meta contains a list of data itmes.

If a ProcessedPod object comes across a non-standard Format Code letter, it will parse the contents, using the semantics defined for **X**, as described above.

If a template has been supplied of the form `format-ß`, then it will call the template with the enclosed text as `contents` or `meta` as described above.

For example, lets assume that we want a Format Code to access the [Font Awesome Icons](https://fontawesome.com/v4.7.0/icons). The template will need to be defined as follows (assuming the Mustache templater):

```
$r.modify-templates( %( :format-f( '<i class="fa {{{ contents }}}"></i>' ) ));
```
And the pod text would include something like "this text has a F<fa-snowflake-o> icon" in it. Note that although the HTML will be rendered correctly, it will also be necessary to ensure that the `head-block` template is altered so that the `Font Awesome` Javascript library is included.

Alternatively, using `RakuClosure Templates` a FormatCode **S** could be defined as:

```
$r.modify-templates( %( format-s => sub(%prm, %tmpl) {
    '<div class="' ~ %prm<meta> ~ '">' ~ %prm<contents> ~ '</div>'
} ) );
```
In which case

```
    =begin pod
    This is an item for sale S<Click to purchase with XXXProvider | xxxprovider_button>
    =end pod

```
Would yield

```
<div class="xxxprovider_button">Click to ourchase with XXXProvider</div>
```
Naturally, the developer would need to set up significantly more HMTL/JS/CSS boilerplate in the header for this to have any action.

# Plugins
A plugin contains Custom Pod Blocks and Custom Templates, and it may contain other data that cannot be inferred from the Rakudoc (POD6) content files, such as css, scss, HTML scripts, JQuery plugins, etc.

Templates can be added using the `.modify-templates` method.

Custom Pod-Blocks can be added by adding to the `.custom` array.

It is better to use the convenience method `.add-plugin`

```
my $p = ProcessedPod.new;
# some time later in the program
$p.add-plugin( 'my-plugin' );

```
This means that the current working directory contains a sub-directory `my-plugin` with the following structure

```
my-plugin/
-- templates.raku
-- blocks.raku

```
`templates.raku` must be a valid Raku program that evaluates to a `Hash`. There is a difference between the template hash for a plugin, and the template hash for `.modify-templates`.

In order to allow for plugins to be used with multiple template engines, the first level keys may be the name of the templating engine. The first-level keys then point to the extra templates provided by the plugin.

Since the default templating engine is `RakuClosureTemplater` the first level keys are tested to see whether they include **rakuclosuretemplater**. If so, other keys correspond to other templating engines.

The current valid keys (case insensitive) are:

*  MustacheTemplater

*  CroTemplater

*  RakuClosureTemplater

If the **rakuclosuretemplater** key exists, then the templates corresponding to the `.templater.Str.lc` method chain are chosen.

If the templater engine is **not** `RakuClosureTemplater` and the plugin templates do not contain a key for the templater engine, then a `X::ProcessedPod::BadPluginTemplates` will be thrown.

`add-plugin` is defined as

```
add-plugin(Str $plugin-name,
  :$path = $plugin-name,
  :$template-raku = "templates.raku",
  :$custom-raku = "blocks.raku",
  :%config is copy
)
```
so a different path can be set, such as a subdirectory of the CWD, and different file names for `template.raku` and `custom.raku`.

A plugin can provide its own config data, eg., css, script, strings. These may then be used by other plugins to affect templates for the output files. The strings will be interpreted by those plugins.

A plugin can only be added once to an object, as a precaution against over-writing. Adding the same name again will cause the method to throw an <X::ProcessedPod::NamespaceConflict> exception.

Each of the raku programs are evaluated with the working directory path set to `:path`. For example, given

```
my-plugin/
-- some-dir/
------ templates.raku
-- blocks.raku
-- file-containing-data

```
`ProcessedPod::add-plugin` will change directory to `my-plugin` and run `some-dir/templates.raku` from there. If `templates.raku` needs to access `file-containing-data` it should do so like:

```
'file-containing-data'.IO.slurp
```
# External Data
When rendering multiple files (see [Rendering Strategy](Rendering Strategy.md)), it is useful to be able to add data to the `ProcessedPod` object (eg. `$pp`), which can then be used by a custom Pod::Block and accompanying template. The custom block and the template can be introduced by the `.add-plugin` method, but the extra data can be added separately, eg., after other files have been rendered.

This is done with the `.add-data` method, eg.

```
$pp.add-data('name-space', $data-object)
```
It is only permitted to write to a name-space once. An attempt to overwrite the data will throw an <X::ProcessedPod::NamespaceConflict> exception.

# Rendering Strategy
A rendering strategy is required for a complex task consisting of many Pod sources. A rendering strategy has to consider:

*  The pod contained in a single file may be provided as one or more trees of Pod blocks. A pod tree may contain blocks to be referred to in a Table of Contents (TOC), and also it may contain anchors to which other documentation may point. This means that the pod in each separate file will automatically produces its own TOC (a list of headers in the order in which they appear in the pod tree(s), and its own Glossary (a list of terms that are encountered, perhaps multiple times for each term, within the text).

*  When only a single file source is used (such as when a Pod::To::name is called by the compiler), then the content, TOC and glossary have to be rendered together.

*  Multiple pod files will by definition exist in a collection that should be rendered together in a consistent manner. The content from a single source file will be called a **Component**. This will be handled in another module raku-render-collection There have to be the following facilities

*  A strategy to create one or more TOC's for the whole collection that collect and combine all the **Component** TOC's. The intent is to allow for TOCs that are designed and do not follow the alphabetical name of the **Component** source, together with a default alphabetical list.

*  A strategy to create one or more Glossary(ies) from all the **Component** glossaries

# Rendering many Pod Sources
A complete render strategy has to deal with multiple page components.

The following sketches the use of the `Pod::To::HTML2` class.

For example, suppose we want to render each POD source file as a separate html file, and combine the global page components separately.

The the `ProcessedPob` object expects a compiled Pod object. One way to do this is use the `Pod::From::Cache` module.

```
    use Pod::To::HTML2;
    my $p = Pod::To::HTML2.new;
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
            @processed.append: $p.emit-and-renew-processed-state;
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
## add-plugin
This is documented above. It is defined as:

```
method add-plugin(Str $plugin-name,
      :$path = $plugin-name,
      :$template-path = "$path/templates.raku",
      :$custom-path = "$path/blocks.raku",
      :%config
      )
```
## add-custom( $block )
A method for adding strings to the @.custom array.

If $block is a Str then it is a path to a Raku program that evaluates to an Array, whose elements are appended to @.custom.

If $block is an Array, then the elemsnts are added to @.custom.

## add-templates( $template )
Like `add-custom`, if $template is a hash, it will be given to modify templates, otherwise it will be consiered a program that evaluates to a hash.

# add-data( $name-space, $object )
Adds the object to the data area of the `ProcessedPod` object with the key <name-space>.

# get-data( $name-space )
Returns the data object.

## process-pod
```
method process-pod( $pod )
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
Returns the PodFile object (see below) containing the data collected from a processed file. The rendered text is not kept, and should be handled before using this method.

A new PodFile object is instantiatedd, which deletes any previously processed pod, keeping the template engine cache

## file-wrap
```
method file-wrap(:$filename = $.name, :$ext = 'html' , :$dir = '')
```
Saves the rendered pod tree as a file, and its document structures, uses source wrap Filename defaults to the name of the pod tree, and ext defaults to html, to another directory dir.

So `.file-wrap(:filename(fn),:ext<txt>,:dir<some/other/path> )` would be `some/other/path/fn.txt`

Raku has limits on file system management, so this may fail if the directory does not exist.

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
Within the templating Role

```
    #| the following are required to render pod. Extra templates, such as head-block and header can be added by a subclass
    has @.required = < block-code comment declarator defn dlist-end dlist-start escaped footnotes format-b format-c
        format-i format-k format-l format-n format-p format-r format-t format-u format-x glossary heading
        item list meta unknown-name output para pod raw source-wrap table toc >;
    #| must have templates. Generically, no templates loaded.
    has Bool $.templates-loaded is rw = False;
    has $.templater-is is rw = 'rakuclosure';
    #| storage of loaded templates
    has %.tmpl;
    #| a variable to collect which templates have been used for trace and debugging
    has BagHash $.templs-used .= new;

```
Within the PodFile class

```
    #| Text between =TITLE and first header, this is used to refer for textual placenames
    has $.front-matter is rw = 'preface';
    #| Name to be used in titles and files.
    has Str $.name is rw is default('UNNAMED') = 'UNNAMED';
    #| The string part of a Title.
    has Str $.title is rw is default('UNNAMED') = 'UNNAMED';
    #| A target associated with the Title Line
    has Str $.title-target is rw is default(DEFAULT_TOP) = DEFAULT_TOP;
    has Str $.subtitle is rw is default('') = '';
    #| should be path of original document, defaults to $.name
    has Str $.path is rw is default('UNNAMED') = 'UNNAMED';
    #| defaults to top, then becomes target for TITLE
    has Str $.top is rw is default(DEFAULT_TOP) = DEFAULT_TOP;

    # document level information

    #| language of pod file
    has $.lang is rw is default('en') = 'en';
    #| information to be included in eg html header
    has @.raw-metadata;
    #| toc structure , collected and rendered separately to body
    has @.raw-toc;
    #| glossary structure
    has %.raw-glossary;
    #| footnotes structure
    has @.raw-footnotes;
    #| when source wrap is called
    has Str $.renderedtime is rw is default('') = '';
    #| the set of targets used in a rendering process
    has SetHash $.targets .= new;
    #| config data given to the first =begin pod line encountered
    #| there may be multiple pod blocks in a file, and they may be
    #| sequentially rendered.
    #| Can contain information about rendering footnotes/toc/glossary/meta
    #| Template used can be changed on a per file basis
    has %.pod-config-data is rw;
    #| Structure to collect links, eg. to test whether they all work
    has %.links;
    #| the templates used to render this file
    has BagHash $.templates-used is rw;

```
Within the GenericPod class

```
    has PodFile $.pod-file .= new;

    # Output rendering information set by environment
    #| set to True eliminates meta data rendering
    has Bool $.no-meta is rw = False;
    #| set to True eliminates rendering of footnotes
    has Bool $.no-footnotes is rw = False;
    #| set to True to exclude TOC even if there are headers
    has Bool $.no-toc is rw = False;
    #| set to True to exclude Glossary even if there are internal anchors
    has Bool $.no-glossary is rw = False;

    # Output set by subclasses or collection

    #| default extension for saving to file
    #| should be set by subclasses
    has $.def-ext is rw is default('') = '';

    # Data relating to the processing of a Pod file

    # debugging
    #| outputs to STDERR information on processing
    has Bool $.debug is rw = False;
    #| outputs to STDERR more detail about errors.
    has Bool $.verbose is rw = False;

    #| defaults to not escaping characters when in a code block
    has Bool $.no-code-escape is rw is default(False) = False;

    # populated by process-pod method
    #| single process call
    has Str $.pod-body is rw;
    #| concatenation of multiple process calls
    has Str $.body is rw = '';
    #| metadata when rendered
    has Str $.metadata;
    #| rendered toc
    has Str $.toc;
    #| rendered glossary
    has Str $.glossary;
    #| rendered footnotes
    has Str $.footnotes;
    #| A pod line may have no config data, so flag if pod block processed
    has Bool $.pod-block-processed is rw = False;

    #| custom blocks
    has @.custom = ();
    #| plugin data, accessible via add/get plugin-data
    has %!plugin-data = {};

```
# Templates
More information can be found in [PodTemplates](PodTemplates.md)

There is a minimum set of templates that must be provided for a Pod file to be rendered. These are:

```
    < block-code comment declarator defn dlist-end dlist-start escaped footnotes format-b format-c
        format-i format-k format-l format-n format-p format-r format-t format-u format-x glossary heading
        item list meta unknown-name output para pod raw source-wrap table toc >

```
When the `.templates` method is called, the templates will be checked against this list for completeness. An Exception will be thrown if all the templates are not provided. Extra templates can be included. `Pod::To::HTML2` uses this to have partial templates that use the required templates.







----
Rendered from RenderPod at 2022-10-28T16:54:51Z