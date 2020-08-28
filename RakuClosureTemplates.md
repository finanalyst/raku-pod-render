# Raku Closure Templates
>Templates are Raku Subroutines


----
## Table of Contents
[Template structure](#template-structure)  
[The %prm keys](#the-prm-keys)  
[The %tml Hash](#the-tml-hash)  
[Head](#head)  
[Structure syntax](#structure-syntax)  
[Examples](#examples)  

----
In order to increase the speed of Pod6 Renderering, it was necessary for the templates to be compiled directly into subroutines. On one hand, this offers the opportunity for the templates to become much more flexible, as data can be manipulated, but on the other hand, the templates become more difficult to understand.

This distribution provides a tool for testing any set of templates against the [minimum template set](PodTemplates.md) and against custom templates whose structure is passed to it.

# Template structure
The templates are collected together into a hash of subroutines. With the sole exceptions of 'raw' and 'escaped', every subroutine has the form 'template-name' => sub (%prm, %tml) { ... }; # the exceptions are 'escaped' => sub ( $s ) { $s.trans( ... , ... ); } 'raw' => sub ( $s ) { $s };

In fact, 'escaped' and 'raw' are treated specially by the `RakuClosureTemplater` Role. `GenericPod` provides the information to both as a hash with the text in `contents`. This text is extracted and sent to the `escaped` template as a string, and simply returned without template processing for `raw`.

The hash `%prm` contains the parameters to be included in the template, `%tml` contains the hash of the templates.

# The `%prm` keys
Each key may point to a `Str` scalar or a `Hash`. Any other structure will be rejected by the `test-templates.raku` tool, and will most probably throw an exception. In any case, `GenericPod` does not generate template requests with any other structure.

Within the top-level `Hash`, the keys may point to a `Str`, a `Hash` or an `Array`. The elements of these are in the table:

>Elements of %prm hash

 | level | allowable Type | element Type |
|:----:|:----:|:----:|
 | top | Str | n/a |
 | top | Hash | Str |
 |  |  | Bool |
 |  |  | Hash |
 |  |  | Array |
 | ! top | Str | n/a |
 | ! top | Bool | n/a |
 | ! top | Hash | Str |
 |  |  | Bool |
 |  |  | Hash |
 |  |  | Array |
 | ! top | Array | Str |
 | ! top | Array | Hash |

# The `%tml` Hash
This is the hash of the subroutines.

There should be no reason to call `raw` since it is anticipated it will be the same as the characters themselves.

The `escaped` template should be called as %tml<escaped>( ｢some string｣ )

Another template typically will be called as %tml<toc>( %prm, %tml)

However, since a template is a normal **Raku** subroutine, `%prm` could be substituted with any `Hash`, eg., %tml<title>( { :title(｢Some arbitrary string｣) }, %tml )

# head

test-templates.raku

This testing tool has the structure of the minimum template set coded into it. It is called as raku test-templates.raku --extra='filename-of-custom-template-structure.raku' --verbose 'filename-of-templates.raku'

> **--extra (optional, default: C&lt;Any&gt; )**  
This is a B<Raku> compilable program that returns a C<Hash> with the structure of the key, more below.
> **--verbose (optional, default: False )**  
A boolean that if True will print out the result of the test for each template
> **'filename-of-templates.raku' (mandatory, string)**  
A B<Raku> compilable program that returns a C<Hash> contains all the minimum templates as keys pointing subroutines.
If the minimum set of templates is not provided, a `MissingTemplates` exception will be thrown.

Since all the templates are provided to all the templates, it is recommended to use sub-templates within the minimum set to simplify the code.

## Structure syntax
As can be seen from the table above, two scalars may be elements of a Hash, namely 'Bool' and 'Str'. These are given as `Str` values, eg. 'title' => 'Str', 'heading' => { :text('Str'), :level('Str'), :is-header('Bool') }

A `Hash` element is specified as a `Hash`, as shown above and a `Array` as an `Array`, eg. 'table' => { :rows( [ 'Str', ] ) }

# Examples
Examples of a set of RakuClosureTemplates can be found in the `resources` directory of the distribution, as



*  `closure-temp.raku` is an array of templates, including a custom `image` template. The templates are designed for `Pod::To::HTML`.

*  `extra-test.raku` is a hash with the template structure for the `image` template.






----
Rendered from RakuClosureTemplates at 2020-08-28T23:43:27Z