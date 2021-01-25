# Raku::Pod::Render
>Change log



----
# Prior to 2021-01-17
*  Module runs, passes all tests.

*  P2HTML passes all legacy tests

*  custom blocks

*  custom templates

# 2021-01-17
*  resolved issue relating to name. Changed Pod::To::HTML to Pod::To::HTML2

# 2021-01-18
*  added CHANGELOG.pod6 / CHANGELOD.md

*  Added functionality to Unused **FormatCodes**

	*  Codes such as **L** and **X** have the form `CodeLetter<some content | data ; more data> `

	*  The `Pod::Block` then provides **some content** as `contents` and then `meta` is a list of **'data', 'more data'**

	*  This syntax is applied to all non-standard format codes

*  added new test for formatting

*  refactored tests

	*  removed meta file test to xt/ and so no need for Environment flag

	*  moved several large testing modules from test-depends to depends

*  modified xt/100-html/150* to not run unless SHELL_TEST environment set

*  spun off Extractor to a different module 'raku-pod-extraction'

	*  Changed all documentation references to Extractor

*  removal of Extractor removes dependence on GTK::Simple

	*  resolves issue regarding GTK::Simple

# 2021-01-19
*  change installation default from installing highlighter to not installing highlighter

*  added utility to install highlighter post installation

# 2021-01-20
*  change META6.json to ensure module passes tests with prove6 -I.

# 2021-01-22
*  improve css

	*  change nav ids to _TOC/_Glossary to avoid name clash with possible block names TOC or Glossary

	*  change tests of TOC and Glossary

	*  error in footnote scss

*  change templates so that no nav divs appear when no component structures have content.

# 2021-01-23
*  add $.templs-used to Template manager. records each time a template is used during rendering. The intention is to make the information available for debugging when dealing with multiple files.

*  test added to xt/030* for templates-used

*  extend to other named & header Pod::Blocks the ability to use another template if given as a config variable.

# 2021-01-25


*  fix default Markdown template of metadata

*  fix default Markdown of =defn blocks

*  change Perl 6 => Raku in tests, except non-breaking space






----
Rendered from CHANGELOG at 2021-01-25T22:09:21Z