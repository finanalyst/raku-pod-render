# Raku Closure Templates

----
----
## Table of Contents
[Template structure](#template-structure)  
[The %prm keys](#the-prm-keys)  
[The %tml Hash](#the-tml-hash)  

----
In order to increase the speed of Pod6 Renderering, it was necessary for the templates to be compiled directly into subroutines. On one hand, this offers the opportunity for the templates to become much more flexible, as data can be manipulated, but on the other hand, the templates become more difficult to understand.

This distribution provides a tool for testing any set of templates against the [minimum template set](PodTemplates.md) and against custom templates whose structure is passed to it.

# Template structure
The templates are collected together into a hash of subroutines. With the sole exceptions of 'raw' and 'escaped', every subroutine has the form

```
'template-name' => sub (%prm, %tml) { ... };
# the exceptions are
'escaped' => sub ( $s ) { $s.trans( ... , ... ); }
'raw' => sub ( $s ) { $s };
```
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
This is the hash of all the templates, except `raw` since it is anticipated `raw` will only be the same as the characters in the string themselves. `raw` is there to be an alternative to `escaped`.

The `escaped` template should be called as

```
%tml<escaped>( ｢some string｣ )
```
Another template typically will be called as

```
%tml<toc>( %prm, %tml)
```
However, since a template is a normal **Raku** subroutine, `%prm` could be substituted with any `Hash`, eg.,

```
%tml<title>( { :title(｢Some arbitrary string｣) }, %tml ).
```
The presence of %tml is to allow for templates to call other templates.







----
Rendered from RakuClosureTemplates at 2021-02-27T20:13:10Z