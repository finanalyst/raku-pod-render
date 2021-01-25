use ProcessedPod;
unit class Pod::To::MarkDown:auth<github:finanalyst> is ProcessedPod;
has $.def-ext is rw;

submethod TWEAK {
    $!def-ext = 'md';
    if 'md-templates.raku'.IO.f { self.templates('md-templates.raku') }
    else { self.templates( self.md-templates) }
}
method rewrite-target(Str $candidate-name is copy, :$unique --> Str ) {
    state SetHash $targets .= new;
    # when indexing a unique target is needed even when same entry is repeated
    # when a Heading is a target, the reference must come from the name
    # the following algorithm for target names comes from github markup
    # https://gist.github.com/asabaylus/3071099#gistcomment-2563127
    #        function GithubId(val) {
    #	return val.toLowerCase().replace(/ /g,'-')
    #		// single chars that are removed
    #		.replace(/[`~!@#$%^&*()+=<>?,./:;"'|{}\[\]\\–—]/g, '')
    #		// CJK punctuations that are removed
    #		.replace(/[　。？！，、；：“”【】（）〔〕［］﹃﹄“”‘’﹁﹂—…－～《》〈〉「」]/g, '')
    #}
    $candidate-name = $candidate-name.lc
            .subst(/\s+/,'-',:g)
            .subst(/<[`~!@#$%^&*()+=<>,./:;"'|{}\[\]\\–—]>/,'',:g)
            .subst( /<[。！，、；：“【】（）〔〕［］﹃﹄”’﹁﹂—…－～《》〈〉「」]> /, '' , :g);
    if $unique {
        $candidate-name ~= '-0' if $candidate-name (<) $targets;
        ++$candidate-name while $targets{$candidate-name}; # will continue to loop until a unique name is found
    }
    $targets{ $candidate-name }++; # now add to targets, no effect if not unique
    $candidate-name
}

method render( $pod-tree ) {
    state $rv;
    return $rv with $rv;
    # Some implementations of raku/perl6 called the classes render method twice,
    # so it's necessary to prevent the same work being done repeatedly

    my $pp = self.new(:name($*PROGRAM-NAME), :no-glossary);
    $pp.process-pod($pod-tree);
    # Outputs the string with a top, tail, TOC and Glossary
    $rv = $pp.source-wrap;
}

method md-templates {
    %(
        'nl' => ~$?NL, # OS dependent new line
        'nl2' => ~ ($?NL x 2),
        'sp2' => "  ",
        'escaped' => -> %params {
            if ( %params<contents> ~~ / \`/ ) {
                %params<contents> .= trans( [ q{`}  ] =>
                                            [ q{``} ] )
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
        'format-l' => '[{{{ contents }}}]({{# internal }}#{{/ internal }}{{ target }}{{# local }}.md{{/ local }})',
        'format-n' => '[ {{ fnNumber }} ]',
        'format-p' => '```{{^ html }}{{> nl }}<pre>{{/ html }}{{{ contents }}}{{^ html }}</pre>{{/ html }}{{> nl2 }}',
        'format-r' => '"> \{\{\{ contents }}}{{> nl2 }}',
        'format-t' => '{{> format-r }}',
        # No separate underline in standard MarkDown, so choice is to be same as -i
        'format-u' => '_{{{ contents }}}_',
        # Markdown does not provide a mechanism for inline anchors, so place is the most recent header
        'format-x' => '{{{ text }}} ',
        'heading' => -> %params { '#' x %params<level> ~ ' {{ text }}{{> nl}}' } ,
        'item' => ' {{{ contents }}}',
        'list' => -> %params {'{{# items }}' ~ "\t" x %params<nesting> ~ '* {{{ . }}}{{/ items}}'},
        'named' =>  -> %params { '#' x %params<level> ~ ' {{ name }}{{> nl2 }}{{{ contents }}}' } ,
        'pod' => '{{> section }}',
        'notimplemented' => '*{{{ contents }}}*',
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
            {{> title }}
            {{> subtitle }}
            {{# toc }}
            ----
            {{{ toc }}}{{/ toc }}
            ----
            {{{ body }}}
            {{# footnotes }}
            ----
            {{{ footnotes }}}{{/ footnotes }}
            {{# meta }}
            ----
            {{{ metadata }}}{{/ metadata }}
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
        'meta' => '> {{# meta }} **{{ name }}** {{ value }}{{/ meta }}{{> nl2 }}',
        'toc' => q:to/TEMPL/,
            ## Table of Contents
            {{# toc }}
            [{{ text }}](#{{ target }}){{> sp2 }}
            {{/ toc }}
            TEMPL
        'header' => '',
        'footer' => '{{# path }}Rendered from {{ path }}{{/ path }}{{# renderedtime }} at {{ renderedtime }}{{/ renderedtime }}{{# path }}{{/ path }}'
    )
}