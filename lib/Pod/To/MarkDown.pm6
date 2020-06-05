=begin pod

=head Usage with compiler

    From the terminal:
    =begin code :lang<shell>
    raku --doc=MarkDown input.raku > README.md
    =end code

    Rendering options for the renderering module cam be passed via the PODRENDER Environment variable, Eg.
    =begin code :lang<shell>
    PODRENDER='NoTOC NoMETA NoGloss NoFoot' raku --doc=MarkDown input.raku > README.md
    =end code

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

=head More and Differences from Pod::To::HTML

    See C<Pod::To::HTML> for more detail. Essentially the same as that class, but
    with different templates to produce MarkDown and not HTML.

    =item There is no need to reproduce the node2html or pod2html functions.

    =item The target rewrite function needs to be over-ridden.

    =item The limitations of MarkDown mean that Footnotes have to be rendered at the end of the document, and there is
    no know way (by the author) to place targets into the footnote that refers back to the original anchor.

    =item as for Footnotes, a Glossary cannot contain links to the text, so only a text location is provided. This makes
    a Glossary structure pretty well useless for an MD document. The default therefore is to turn off glossaries.

=end pod

unit class Pod::To::MarkDown;
use ProcessedPod;

class MDProcessedPod is ProcessedPod {
    method rewrite-target(Str $candidate-name is copy, :$unique --> Str ) {
        state SetHash $targets .= new;
        # target names inside the POD file, eg., headers, glossary, footnotes
        # function is called to cannonise the target name and to ensure - if necessary - that
        # the target name used in the link is unique.
        # This method uses the default algorithm for HTML and POD
        # It may need to be over-ridden, eg., for MarkDown which uses a different targetting function.

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
                .subst(/<[`~!@#$%^&*()+=<>?,./:;"'|{}\[\]\\–—]>/,'',:g)
                .subst( /<[　。？！，、；：“”【】（）〔〕［］﹃﹄“”‘’﹁﹂—…－～《》〈〉「」]> /, '' , :g);
        if $unique {
            $candidate-name ~= '-0' if $candidate-name (<) $targets;
            ++$candidate-name while $targets{$candidate-name}; # will continue to loop until a unique name is found
        }
        $targets{ $candidate-name }++; # now add to targets, no effect if not unique
        $candidate-name
    }
}

method render( $pod-tree ) {
    state $rv;
    return $rv with $rv;
    # Some implementations of raku/perl6 called the classes render method twice,
    # so it's necessary to prevent the same work being done repeatedly

    my MDProcessedPod $processor .= new(
        :tmpl( md-templates() ),
        :name( $*PROGRAM-NAME )
    );
    # takes the pod tree, escape any backticks in the Pod, then and wraps it in MarkDown.
    $processor.process-pod( $pod-tree.subst( / \`/ , '``' ) );

    # Outputs the string with a top, tail, TOC and Glossary
    $rv = $processor.source-wrap;
}

method processor {
    MDProcessedPod.new( :tmpl( md-templates() ) )
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

        'format-n' => '[ {{ fnNumber }} ]',

        'format-p' => "```\{\{^ html }}\n<pre>\{\{/ html }}\{\{\{ contents }}}\{\{^ html }}</pre>\{\{/ html }}\n```\n",

        'format-r' => "> \{\{\{ contents }}}\n\n",

        'format-t' => "> \{\{\{ contents }}}\n\n",

        # No separate underline in standard MarkDown, so choice is to be same as -i
        'format-u' => '_{{{ contents }}}_',
        # Markdown does not provide a mechanism for inline anchors, so place is the most recent header
        'format-x' => '{{{ text }}} ',

        'heading' => -> %params { '#' x %params<level> ~ ' {{ text }}' ~ "\n" } ,

        'item' => ' {{{ contents }}}',

        'list' => q:to/TEMPL/,
                    {{# items }}* {{{ . }}}{{/ items}}
            TEMPL

        'named' =>  -> %params { '#' x %params<level> ~ ' {{ name }}' ~ "\n\n" ~ '{{{ contents }}}' } ,

        'notimplemented' => '*{{{ contents }}}*',

        'output' => "> \{\{\{ contents }}}\n\n",

        'para' => '{{{ contents }}}
        ',

        'section' => '{{{ contents }}}' ~ "\n\n" ~ '{{{ tail }}}' ~ "\n\n",

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
            {{# path }}Rendered from {{ path }}{{/ path }}{{# renderedtime }} at {{ renderedtime }}{{/ renderedtime }}{{# path }}{{/ path }}
            TEMPL

        'footnotes' => q:to/TEMPL/,
            {{# notes }}
            ###### {{ fnNumber }}
                {{{ text }}}
            {{/ notes }}
            TEMPL

        'glossary' => q:to/TEMPL/,
            ## Glossary
                {{# glossary }}
                ##### {{{ text }}}
                    {{{ place }}}
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