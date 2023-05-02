use v6;
%(
    '_templater' => 'MustacheTemplater',
    'nl' => ~$?NL,
    # OS dependent new line
    'nl2' => ~($?NL x 2),
    'sp2' => "  ",
    :github_badge(''),
    'escaped' => -> %params {
        if (%params<contents> ~~ / \`/) {
            %params<contents> .= trans([q{`}] => [q{``}])
        }
        '{{{ contents }}}'
    },
    :raw<{{{ contents }}}>,
    'block-code' => q:to/TEMPL/,
        ```
        {{# contents }}{{{ contents }}}{{/ contents }}
        ```
        TEMPL
    # eliminate POD comments
    'comment' => '',
    'declarator' => '## {{{ code }}}{{> nl2 }}{{{ contents }}}{{> nl2 }} ',
    # Markup doesn't have Definition lists. This seems a nice way to mimic them
    'dlist-start' => '',
    'defn' => '> **{{ term }}**  {{> nl }}{{{ contents }}}{{> nl2 }}',
    :dlist-end(''),
    'format-b' => '**{{{ contents }}}**',
    'format-c' => '`{{{ contents }}}`',
    'format-i' => '_{{{ contents }}}_',
    'format-k' => '> {{{ contents }}}{{> nl2 }}',
    'format-l' => '[{{{ link-label }}}]({{# external }}{{ target }}{{/ external}}{{# internal }}{{{ place }}}{{/ internal }}{{# local }}{{ target }}.md{{# place }}#{{ place }}{{/ place}}{{/ local }})',
    'format-n' => '[ {{ fnNumber }} ]',
    'format-p' => '```{{^ html }}{{> nl }}<pre>{{/ html }}{{{ contents }}}{{^ html }}</pre>{{/ html }}{{> nl2 }}',
    'format-r' => '"> \{\{\{ contents }}}{{> nl2 }}',
    'format-t' => '{{> format-r }}',
    # No separate underline in standard MarkDown, so choice is to be same as -i
    'format-u' => '_{{{ contents }}}_',
    # Markdown does not provide a mechanism for inline anchors, so place is the most recent header
    'format-x' => '{{{ text }}} ',
    'heading' => -> %params { '#' x %params<level> ~ ' {{ text }}{{> nl}}' },
    'item' => ' {{{ contents }}}',
    'list' => -> %params { '{{# items }}' ~ "\t" x %params<nesting> ~ '* {{{ . }}}{{/ items}}' },
    'nested' => '> {{{ contents }}}{{> nl2 }}',
    'unknown-name' => -> %params { '#' x %params<level> ~ ' {{ name }}{{> nl2 }}{{{ contents }}}' },
    'pod' => '{{> section }}',
    'input' => '> {{{ contents }}}{{> nl2 }}',
    'output' => '> {{{ contents }}}{{> nl2 }}',
    'para' => '{{{ contents }}}{{> nl2 }}',
    'section' => '{{{ contents }}}{{> nl2 }}{{{ tail }}}{{> nl2 }}',
    'subtitle' => '>{{{ subtitle }}}{{> nl }}',
    'table' => q:to/TEMPL/,
        {{# caption }}>{{{ caption }}}{{> nl }}{{/ caption }}
        {{# headers }}{{# cells }} | {{{ . }}}{{/ cells }} |
        {{# cells }}|:----:{{/ cells}}|
        {{/ headers }}
        {{# rows }}{{# cells }} | {{{ . }}}{{/ cells }} |{{> nl }}{{/ rows }}
        TEMPL
    'title' => '# {{{ title }}}{{> nl }}',
    # templates used by output methods, eg., source-wrap, file-wrap, etc
    # In HTML Meta tags can go in the Head section, but for Markdown they will be at the top above the TOC.
    'source-wrap' => q:to/TEMPL/,
        {{> github_badge }}
        {{> title }}
        {{> subtitle }}
        {{# metadata }}
        {{{ metadata }}}
        ----
        {{/ metadata }}
        {{# toc }}
        ## Table of Contents
        {{{ toc }}}
        ----
        {{/ toc }}
        {{{ body }}}
        {{# footnotes }}
        ----
        {{{ footnotes }}}{{/ footnotes }}
        ----
        {{> footer }}
        TEMPL
    'footnotes' => q:to/TEMPL/,
        {{# notes }}
        ###### {{ fnNumber }}
        {{{ text }}}
        {{/ notes }}
        TEMPL
    'glossary' => '',
    'meta' => '{{# meta }}> **{{ name }}** {{ value }}{{> nl2 }}{{/ meta }}',
    'toc' => q:to/TEMPL/,
        {{# toc }}
        [{{ text }}](#{{ target }}){{> sp2 }}
        {{/ toc }}
        TEMPL
    'header' => '',
    'footer' => 'Rendered from {{ config.path }} at {{ renderedtime }}'
);
