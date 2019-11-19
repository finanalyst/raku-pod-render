=begin pod

=head Usage with compiler
    From the terminal:
    C<raku --doc=HTML input.raku > output.html>

    Rendering options for the renderering module cam be passed via the PODRENDER Environment variable, Eg.
    C<PODRENDER='NoTOC NoMETA NoGloss NoFoot' raku --doc=HTML input.raku > output.html>

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

=head Standalone usage
    Inside a raku program, for a work flow that assumes the output as HTML snippets (as in a test file,
    or for a sequence of pod-trees that will be stitched together in a single file).

    =begin code
        use Pod::To::HTML;
        # for repeated pod trees to be output as a single page or html snippets (as in a test file)
        my $renderer = Pod::To::HTML.processor(:name<Optional name defaults to UNNAMED>);
        # processor() actually returns a ProcessedPod instance. More details on parameters and functions there
        ... # later
        =begin pod
            some pod
        =end pod
        say 'The rendered pod is: ', $renderer.body-only( $=pod );
        =begin pod
            another fact-filled assertion
        =end pod
        say 'The next pod snippet is: ', $renderer.body-only( $=pod[*-1] );
        #later
        my $output-string = $renderer.source-wrap;
        # will return a full HTML string.
        # if there are headers in the accumulated pod, then a TOC will be generated and included
        # if there are X<> type references in the accumulated pod, then a Glossary will be generated and included

        $renderer.file-wrap(:output-file<some-useful-name>, :ext<html>);
        # first .source-wrap is called and then output to a file.
        # if ext is missing, 'html' is used
        # if C<some-useful-name> is missing, C<name> is used, which defaults to C<UNNAMED>
        # C<some-useful-name> could include a valid path.
    =end code

    Inside a raku program for an application that assumes each file is to be output as a separate html file

    =begin code
        use Pod::To::HTML;
        my %pod-input; # key is the path-name for the output file, value is a Pod::Block
        my @processed;
        # ... populate @pod-input, eg from a document cache

        for %pod-input.kv -> $nm, $pd {
            my Pod::To::HTML $p .= processor;
            @processed.append: $p;
            with $p {
                .name = $nm;
                # change templates on a per file basis before calling process-pod
                .tmpl<format-b> =  '<strong class="myStrongClass {{# addClass }}{{ addClass }}{{/ addClass }}">{{{ contents }}}</strong>';
                # was 'format-b' => '<strong{{# addClass }} class="{{ addClass }}"{{/ addClass }}>{{{ contents }}}</strong>'
                # the effect of this change is to add myStrongClass to all instances of B<> including any extra classes added by the POD
                .process-pod( $pd )
            }
        }
        # each instance of @processed will have TOC and Glossary arrays that can be combined in some way
        # turnoff the glossary and TOC for each file
        for @processed {
            .no-toc = True;
            .no-glossary = True;
            # change templates used for outputing, most likely use is to change 'source-wrap' to include custom js-scripts
            .file-wrap; #defaults to $.name for file, and 'html' for extension
        }
        # code to write global TOC and Glossary html files.
    =end code

=end pod

unit class Pod::To::HTML;
use ProcessedPod;

method render( $pod-tree ) {
    state $rv;
    return $rv with $rv;
    # Some implementations of raku/perl6 called the classes render method twice,
    # so it's necessary to prevent the same work being done repeatedly

    my ProcessedPod $processor .= new(
        :tmpl( html-templates() ),
        :name( $*PROGRAM-NAME )
    );
    # takes the pod tree and wraps it in HTML.
    $processor.process-pod( $pod-tree );
    # Outputs a string that describes a html page
    $rv = $processor.source-wrap;
}

method processor {
    ProcessedPod.new( :tmpl( html-templates() ) )
}


sub html-templates {
    %(
        # templates that are used by process-pod
        # note that verbatim V<> does not have its own format because it affects what is inside it (see POD documentation)
        :escaped<{{ contents }}>,
        :raw<{{{ contents }}}>,

        'block-code' => q:to/TEMPL/,
            <pre class="pod-block-code{{# addClass }} {{ addClass }}{{/ addClass}}">{{# contents }}{{{ contents }}}{{/ contents }}</pre>
            TEMPL

        'comment' => '<!-- {{{ contents }}} -->',

        'defn' => '<dl><dt>{{ term }}</dt><dd>{{{ contents }}}</dd></dl>
        ',
        'format-b' => '<strong{{# addClass }} class="{{ addClass }}"{{/ addClass }}>{{{ contents }}}</strong>',

        'format-c' => '<code{{# addClass }} class="{{ addClass }}"{{/ addClass }}>{{{ contents }}}</code>
        ',

        'format-i' => '<em{{# addClass }} class="{{ addClass }}"{{/ addClass }}>{{{ contents }}}</em>',

        'format-k' => '<kbd{{# addClass }}class="{{ addClass }}"{{/ addClass }}>{{{ contents }}}</kbd>
        ',

        'format-l' => '<a href="{{ target }}"{{# addClass }} class="{{ addClass }}"{{/ addClass}}>{{{ contents }}}</a>
        ',

        'format-n' => '<sup><a name="{{ retTarget }}" href="#{{ fnTarget }}">[{{ fnNumber }}]</a></sup>
        ',

        'format-p' => '<div{{# addClass }} class="{{ addClass }}"{{/ addClass }}>{{^ html }}<pre>{{/ html }}{{{ contents }}}{{^ html }}</pre>{{/ html }}</div>',

        'format-r' => '<var{{# addClass }} class="{{ addClass }}"{{/ addClass }}>{{{ contents }}}</var>',

        'format-t' => '<samp{{# addClass }} class="{{ addClass }}"{{/ addClass }}>{{{ contents }}}</samp>',

        'format-u' => '<u{{# addClass }} class="{{ addClass }}"{{/ addClass }}>{{{ contents }}}</u>',

        'format-x' => '{{^ header }}<a name="{{ target }}"></a>{{/ header }}{{# text }}<span class="glossary-entry{{# addClass }} {{ addClass }}{{/ addClass }}">{{{ text }}}</span>{{/ text }} ',

        'heading' => '<h{{# level }}{{ level }}{{/ level }} id="{{ target }}"><a href="#{{ top }}" class="u" title="go to top of document">{{{ text }}}</a></h{{# level }}{{ level }}{{/ level }}>
        ',

        'item' => '<li{{# addClass }} class="{{ addClass }}"{{/ addClass }}>{{{ contents }}}</li>
        ',

        'list' => q:to/TEMPL/,
                <ul>
                    {{# items }}{{{ . }}}{{/ items}}
                </ul>
            TEMPL

        'named' => q:to/TEMPL/,
                <section name="{{ name }}">
                    <h{{# level }}{{ level }}{{/ level }} id="{{ target }}"><a href="#{{ top }}" class="u" title="go to top of document">{{{ name }}}</a></h{{# level }}{{ level }}{{/ level }}>
                    {{{ contents }}}
                </section>
            TEMPL

        'notimplemented' => '<span class="pod-block-notimplemented">{{{ contents }}}</span>',

        'output' => '<pre class="pod-output">{{{ contents }}}</pre>',

        'para' => '<p{{# addClass }} class="{{ addClass }}"{{/ addClass }}>{{{ contents }}}</p>',

        'section' => q:to/TEMPL/,
                <section name="{{ name }}">{{{ contents }}}{{{ tail }}}
                </section>',
            TEMPL
        'subtitle' => '<div class="subtitle{{# addClass }} {{ addClass }}{{/ addClass }}">{{{ contents }}}</div>',

        'table' => q:to/TEMPL/,
                <table class="pod-table{{# addClass }} {{ addClass }}{{/ addClass }}">
                    {{# caption }}<caption>{{{ caption }}}</caption>{{/ caption }}
                    {{# headers }}<thead>
                        <tr>{{# cells }}<th>{{{ . }}}</th>{{/ cells }}</tr>
                    </thead>{{/ headers }}
                    <tbody>
                        {{# rows }}<tr>{{# cells }}<td>{{{ . }}}</td>{{/ cells }}</tr>{{/ rows }}
                    </tbody>
                </table>
            TEMPL

        'title' => '<h1 class="title{{# addClass }} {{ addClass }}{{/ addClass }}" id="{{ target }}">{{{ text }}}</h1>',

        # templates used by output methods, eg., source-wrap, file-wrap, etc
        'source-wrap' => q:to/TEMPL/,
            <!doctype html>
            <html lang="en">
                <head>
                    <title>{{ title }}</title>
                    <meta charset="UTF-8" />
                    <link rel="stylesheet" type="text/css" href="assets/pod.css" media="screen" title="default" />
                    {{# metadata }}{{{ metadata }}}{{/ metadata }}
                </head>
                <body class="pod">
                    {{# toc }}{{{ toc }}}{{/ toc }}
                    {{# glossary }}{{{ glossary }}}{{/ glossary }}
                    <div class="pod-body{{^ toc }} no-toc{{/ toc }}">
                        {{{ body }}}
                    </div>
                    {{# footnotes }}{{{ footnotes }}}{{/ footnotes }}
                    {{# path }}<footer>Rendered from {{ path }}{{/ path }}{{# time }} at {{ time }}{{/ time }}{{# path }}</footer>{{/ path }}
                </body>
            </html>
            TEMPL

        'footnotes' => q:to/TEMPL/,
            <div class="footnotes">
                <ol>{{# notes }}
                    <li id="{{ fnTarget }}">{{{ text }}}<a class="footnote" href="#{{ retTarget }}"> « Back »</a></li>
                    {{/ notes }}
                </ol>
            </div>
            TEMPL


        'glossary' => q:to/TEMPL/,
                <table id="glossary">
                    <caption><h2 id="source-glossary">Glossary</h2></caption>
                    {{# glossary }}
                    <tr class="glossary-defn-row">
                        <td class="glossary-defn">{{{ text }}}</td><td></td></tr>
                        {{# refs }}<tr class="glossary-place-row"><td></td><td class="glossary-place"><a href="#{{ target }}">{{{ place }}}</a></td></tr>{{/ refs }}
                    {{/ glossary }}
                </table>
            TEMPL

        'glossary-entry' => q:to/TEMPL/,
                <div class="glossary-entry">
                    <a href="{{ link }}">{{{ title }}}</a>
                    {{# subtitle }}{{{ subtitle }}}{{/ subtitle }}
                    {{# toc }}<table class="glossary-entry-toc">
                        <tr class="entry-toc-level-{{ level }}">
                            <td class="entry-toc-text"><a href="{{ link }}#{{ target }}">{{{ text }}}</a></td>
                        </tr>
                    </table>
                    {{/ toc }}
                </div>
            TEMPL

        'glossary-heading' => q:to/TEMPL/,
                    <h{{ level }} class="glossary-heading">{{ text }}</h{{ level }}>
                    {{# subtitle }}<p>{{ subtitle }}</p>{{/ subtitle }}
            TEMPL

        'meta' => q:to/TEMPL/,
                {{# meta }}
                    <meta name="{{ name }}" value="{{ value }}" />
                {{/ meta }}
            TEMPL

        'toc' => q:to/TEMPL/,
                <table id="TOC">
                    <caption><h2 id="TOC_Title">Table of Contents</h2></caption>
                    {{# toc }}
                    <tr class="toc-level-{{ level }}">
                        <td class="toc-text"><a href="#{{ target }}">{{ text }}</a></td>
                    </tr>
                    {{/ toc }}
                </table>
            TEMPL
    )
}