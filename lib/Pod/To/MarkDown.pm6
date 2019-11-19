=begin pod

=head Usage with compiler
    From the terminal:
    C<raku --doc=MarkDown input.raku > README.md>

    Rendering options for the renderering module cam be passed via the PODRENDER Environment variable, Eg.
    C<PODRENDER='NoTOC NoMETA NoGloss NoFoot' raku --doc=MarkDown input.raku > README.md>

    The following regexen are applied to PODRENDER and switch off the default rendering of the respective section:
    =defn /:i 'no' '-'? 'toc' /
    Table of Contents
    =defn /:i 'no' '-'? 'meta' /
    Meta information (eg AUTHOR)
    =defn /:i 'no' '-'? 'glossary' /
    the Glossary
    =defn /:i 'no' '-'? 'footnotes' /
    Footnotes.

    Hence any or all of 'NoTOC' 'NoMETA' 'NoGloss' 'NoFoot' may be included in any order.
    Default is to include each section.

=head More
    See C<Pod::To::HTML> for more detail. Essentially the same as that class, but
    with different templates to produce MarkDown and not HTML.

=end pod

unit class Pod::To::MarkDown;
use ProcessedPod;

method render( $pod-tree ) {
    state $rv;
    return $rv with $rv;
    # Some implementations of raku/perl6 called the classes render method twice,
    # so it's necessary to prevent the same work being done repeatedly

    my ProcessedPod $processor .= new(
        :tmpl( md-templates() ),
        :name( $*PROGRAM-NAME )
    );
    # takes the pod tree, escape any backticks in the Pod, then and wraps it in MarkDown.
    $processor.process-pod( $pod-tree.subst( / \`/ , '``' ) );

    # Outputs the string with a top, tail, TOC and Glossary
    $rv = $processor.source-wrap;
}

method processor {
    ProcessedPod.new( :tmpl( md-templates() ) )
}


sub md-templates {
    %(
        # templates that are used by process-pod
        :escaped<{{ contents }}>,
        :raw<{{{ contents }}}>,

        'block-code' => q:to/TEMPL/,
            ```
            {{# contents }}{{{ contents }}}{{/ contents }}
            ```
            TEMPL

        # eliminate POD comments
        'comment' => '',
        # Markup doesn't have Definition lists. This seems a nice way to mimic them
        'defn' => "> **\{\{ term }}**  \n\{\{\{ contents }}}\n\n",

        'format-b' => '**{{{ contents }}}**',

        'format-c' => '`{{{ contents }}}`',

        'format-i' => '_{{{ contents }}}_',

        'format-k' => "> \{\{\{ contents }}}\n\n",

        'format-l' => '[{{{ contents }}}]({{ target }})',

#        'format-n' => '<sup><a name="{{ retTarget }}" href="#{{ fnTarget }}">[{{ fnNumber }}]</a></sup>
#        ',

        'format-p' => "```\{\{^ html }}\n<pre>\{\{/ html }}\{\{\{ contents }}}\{\{^ html }}</pre>\{\{/ html }}\n```\n",

        'format-r' => "> \{\{\{ contents }}}\n\n",

        'format-t' => "> \{\{\{ contents }}}\n\n",

        # No separate underline in standard MarkDown, so choice is to be same as -i
        'format-u' => '_{{{ contents }}}_',

#        'format-x' => '{{^ header }}<a name="{{ target }}"></a>{{/ header }}{{# text }}<span class="glossary-entry{{# addClass }} {{ addClass }}{{/ addClass }}">{{{ text }}}</span>{{/ text }} ',

        'heading' => -> %params { '#' x %params<level> ~ ' {{ text }}' ~ "\n" } ,

        'item' => ' {{{ contents }}}',

        'list' => q:to/TEMPL/,
                    {{# items }}* {{{ . }}}{{/ items}}
            TEMPL

#        'named' => q:to/TEMPL/,
#                <section name="{{ name }}">
#                    <h{{# level }}{{ level }}{{/ level }} id="{{ target }}"><a href="#{{ top }}" class="u" title="go to top of document">{{{ name }}}</a></h{{# level }}{{ level }}{{/ level }}>
#                    {{{ contents }}}
#                </section>
#            TEMPL

        'notimplemented' => '*{{{ contents }}}*',

        'output' => "> \{\{\{ contents }}}\n\n",

        'para' => '{{{ contents }}}
        ',

#        'section' => q:to/TEMPL/,
#                <section name="{{ name }}">{{{ contents }}}{{{ tail }}}
#                </section>',
#            TEMPL
        'subtitle' => "## \{\{\{ contents }}}\n",

        'table' => q:to/TEMPL/,
            {{# caption }}**{{{ caption }}}**{{/ caption }}
            {{# headers }}{{# cells }}|{{{ . }}}{{/ cells }}|
            {{# cells }}|:----:{{/ cells}}|
            {{/ headers }}
            {{# rows }}{{# cells }}|{{{ . }}}{{/ cells }}|{{/ rows }}
            TEMPL

        'title' => "# \{\{\{ contents }}}\n",

        # templates used by output methods, eg., source-wrap, file-wrap, etc
        # In HTML Meta tags can go in the Head section, but for Markdown they will be at the top above the TOC.
        'source-wrap' => q:to/TEMPL/,
            {{{ title }}}
            {{{ subtitle }}}
            ----
            {{# metadata }}{{{ metadata }}}{{/ metadata }}
            ----
            {{# toc }}{{{ toc }}}{{/ toc }}
            ----
            {{{ body }}}
            ----
            {{# footnotes }}{{{ footnotes }}}{{/ footnotes }}
            ----
            {{# glossary }}{{{ glossary }}}{{/ glossary }}
            ----
            {{# path }}Rendered from {{ path }}{{/ path }}{{# time }} at {{ time }}{{/ time }}{{# path }}{{/ path }}
            TEMPL

        'footnotes' => q:to/TEMPL/,
            {{# notes }}
            ###### {{ fnTarget }}
                {{{ text }}}
            {{/ notes }}
            TEMPL

        'glossary' => q:to/TEMPL/,
            ## Glossary
                {{# glossary }}
                ##### {{{ text }}}
                    {{# refs }}{{{ place }}}
                {{/ refs }}
                {{/ glossary }}
            TEMPL

        'meta' => "> \{\{# meta }}**\{\{ name }}**\n  \{\{ value }}\n  \{\{/ meta }}\n\n",

        'toc' => q:to/TEMPL/,
            ## Table of Contents
            {{# toc }}
            [{{ text }}](#{{ target }})
            </tr>
            TEMPL
    )
}