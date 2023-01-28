# Raku::Pod::Render
>Change log


# Prior to 2021-01-17
*  Module runs, passes all tests.

*  P2HTML passes all legacy tests

*  custom blocks

*  custom templates

# 2021-01-17
*  resolved issue relating to name. Changed Pod::To::HTML to Pod::To::HTML2

# 2021-01-18
*  added CHANGELOG.pod6 / CHANGELOG.md

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

# 2021-01-31
*  fixed test-templates, which had suffered bit-rot

*  improved test-templates, so that it now gives more feedback on template contents that are not returned

*  fixed html templates that new test-template feed-back showed were erroneous.

*  fixed and updated RakuClosureTemplates.pod6

*  bump version

# 2021-02-01
*  refactoring in emit-... function.

# 2021-02-02
*  refactored to move all pod-file related variables out to a class that is reinstantiated

*  changed tests because an object not a hash is returned.

*  refactored to change rules for plugin and namespaces. Plugins can add their configs to their namespace

*  namespaces cannot be written to more than once.

# 2021-02-5
*  bump version

*  PodFile gist written, started on ProcessedPod gist

*  fixed failing tests due to renderedtime and path changes

*  HTML2 templates improved and removed need for separate wrap-source function.

# 2021-02-09 v10
*  to get Cro, require rakudo-star:2020.01, but that doesn't like set op (==), so use different test in test-templates

# 2021-02-13 v11
*  added TOC functionality to Custom defined blocks

*  added documentation about TOC and also provision of plugin config data to ProcessedPod

# 2021-02-02-14 v12
*  fixed non-standard FC error when not specially templated, added test.

# 2021-02-20 v3-6-13
*  empty BagHash of templates-used correctly with default, not Nil.

# 2021-02-26 v3-6-14
*  Pod-File gist improved when templates-used is undefined.

*  test 060 improved.

# 2021-02-27 v3-6-15
*  resolved issue with passing legacy css tests

# 2021-02-27 v3-6-16
*  moved functionality of test-templates to pm6

*  added test functions templates-present, templates-match, extra-templates-match

*  rewrite / refactor Documentation files

# 2021-03-4 v3-6-17
*  correct HTML rendering of targets in local files. eg href="filen.html#internal-link"

*  change test accordingly

*  change type of templates-used in PodFile from BagHash to %, and adjust gist.

*  fixed persistent Templates-used error, not emptying.

# 2021-03-25 v3-6-18
*  add change of '::' token to '/' in links. This is (previously) undocumented behaviour of [](.md)

# 2021-03-27 v3-6-19
*  improve [](.md) handling of '::' in file part only.

*  improve test to cover new variations.

# 2021-03-28 v3-6-20
*  add link text to link registration for improved error tracing

# 2021-03-31 v3-6-21
*  add page-data key to be passed to template 'file-wrap'. This is config in first `=pod` line.

# 2021-04-02 v3-6-22
*  trim white space in head texts (occurs if head text is also indexed)

# 2022-02-11 v3-7-0
*  refactored the templating system

	*  move-templating out of ProcessedPod

	*  created an array of tests to identify the templating engine

	*  made templating engines into classes, rather than roles

*  new error occurred where role supplied a BagHash and a new did not initialise it

	*  added a method to the role to reinitialise it.

*  begun to add Cro Web templates as possible option

*  refactored the highlighting system

	*  moved highlighting from templates

	*  created possibility for alternate highlighting engine

	*  made autodetection of template engine into a role

*  refactored Exceptions, putting all exceptions associated with ProcessedPod into one file

*  refactored path names, creating `RenderPod` folder, moved files to more intuitive places

*  renamed pm6 to rakumod

*  renamed sanity tests to make order more logical, testing base roles/classes first

# 2022-02-11 v3-7-1
*  Add github badge to front of a Markdown file.

*  Add TEST_OFFLINE environment flag so that tests can be run offline.

# 2022-02-20 v3-7-2
*  changes to way badge path is calculated, from META6.json & .github directory

*  simplified CI setup

*  modification to templates

# 2022-03-28 v3-7-3
*  Add a check to detect templater that looks for `_templater` in the template hash and if it exists, then it must contain the name of the templater class.

*  add test file to verify the auto-detect and `_templater` key.

*  Add `_templater` key to HTML and MarkDown renderers

*  Change behaviour of css-text. It now over-rides the css template, not the css-text template.

*  The test suite sometimes fails at or after `xt/100-html/015-css-addition.t` The tests individually pass.

*  added :type to Pod::To::HTML that indicates which templating system to use, the default is 'closure' because crotmp causes random test failures.

# 22-06-13 v3-7-4
*  default engine set to 'rakuclosure' because crotmp fails many tests because it does not permit double html injection.

*  correction to CWTR::Hash stops failure in test suite.

# 22-07-08 v3-7-5
*  move to fez

# head

change testing

# 22-07-09 v3-7-6
*  version bump

# 22-07-10 v3-7-7
*  minor changes to README, update CHANGELOG

# 2022-09-24 v3-8-0
*  allow rakudoc to be an alias to pod for a named block

*  make github badge changable in MarkDown

# 2022-10-x v4-0-0
*  Refactor HTML2 to

	*  rely on and accept custom plugins

	*  remove all template reliant tests to Pod-Render folder

	*  introduce Rakudoc-to-html utility to render a single Rakudoc file to html into current directory

*  Change name of MarkDown to MarkDown2

*  Change params of Link FormatCode. Now both local and internal may have targets, the template must handle both. The character # designating a target must be added by a template. Before there was a flag defining local/internal/external, a parameter for contents, and a parameter for target (the file | page name). Now there is an extra parameter `location` defining the location inside the file|page.

*  rename mandatory template `named` tp `unknown-name`, which is called when an unknown named Pod::Block is used.

*  refactor modify-templates for plugins, in order to allow for multiple templating in plugins.

	*  A plugin template file may evaluate to a hash of hashes if the key `RakuClosureTemplater` (case insensitive) exists as a first level key

	*  Each primary key then refers to a templating engine,

	*  the second level keys are the template names.

	*  a plugin's templates are only added to the instance of ProcessedPod using `modify-templates`

	*  when `modify-templates` is called for a plugin, it checks whether the default `RakuClosureTemplater` key is present.

		*  If so, the templates pointed to by `.templater.Str` in the plugin's templates are used, and if not present, then an Exception is thrown.

		*  If not, the plugin is using Rakuclosure templates, so if `.templater.Str` is not `RakuClosureTemplater` then an Exception is thrown

*  remove ExtractPod as Pod::Load is Raku canonical

# 2022-11-15 v4.1.0
*  allow for data object to be rewritten by add-plugin. Use case: the name-space for a plugin needs to be available for the plugin's callables, as it contains config data needed by plugin callables

*  Created a Samples.rakudoc file for Rakudoc-to-html Example

*  rewrote sample plugins for HTML2 from Collection variants.

*  wrote new core plugin move-assets for HTML2 to mimic Collection render milestone functionality

*  rewrote BUILD.pm to copy all plugins from resources to a local default directory

*  basic node2html and pod2html options tested. Uses Rakuclosure, so no mustache options.

# 2022-11-27 v4.1.1
*  improve unknown-name default template

*  improve default templates

# correct

Samples.rakudoc for image

# 2022-12-08 v4.2.0
*  make sure all necessary Pod-blocks can take :template & :name-space meta-data, and pass name-space data to template. Previously this was only done for named blocks.

*  implementing =config directive.

	*  `=config` metadata is provided to all templates as the `config` parameter.

	*  metadata for the outermost `=pod` or `=rakudoc` blocks is included in the `=config` data

*  change 'unknown-name' template so that we can format unknown format codes properly

*  change handler of FormatCode so that 'unknown-name' is called with :format-code.

*  default templates for footer needs changing to generate a time

*  default navigation template to remove tags if no TOC or Glossary.

*  include `add-plugins` to P2HTML2 so that new plugins can added to the distributed ones.

# 2022-12-14 v4.2.1
*  add attribute to PodFile for final output so that it can be accessed later.

	*  use case: Collection plugin 'secondaries' that needs the text following a chosen header so that it can be inserted into another file.

# 2022-12-15 v4.2.2
*  fix error - namespace not in header handler.

# 2022-12-17 v4.2.3
*  add pod-output to PodFile.gist

*  add optional length to GIST for amount of pod-output printed

	*  add test to check this.

# 2022-12-31 v4.3.0
*  add ability to remember previous templates.

	*  works and tests ok for RakuClosure. Does not work for Mustache, perhaps Binding needs adding to LinkedVals Hash???

	*  So LinkedVals Hash is only used for RakuClosures.

# 2023-01-01 v4.3.1
*  handle end of linked list better. prior returns Nil not .cell

# 2023-01-01 v4.3.2
*  refactor Templating to eliminate two copies of tmpl

*  include tests for remembering prior formats

*  fix Mustache renderer to work with memory variant

# 2023-01-08 v4.3.3
*  guarantee empty contents when format-code has zero content, eg., `D<>`.

*  fix `=config` directive to alter lexical level, not its own.

*  add tests for config params sent to templates

# 2023-01-08 v4.3.4
*  add config output when verbose is on.

*  ensure file config available for source-wrap

# 2023-01-22 v4.4.0


*  add debug information to Templating

*  add separate template debug flag

*  fixing link error - external flag not being set properly

	*  Provide parameter type to template with values internal, external, local





----
Rendered from CHANGELOG at 2023-01-28T11:48:20Z