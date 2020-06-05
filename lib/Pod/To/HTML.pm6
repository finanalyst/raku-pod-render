=begin pod

=head Usage with compiler
    From the terminal:
    =begin code :lang<shell>
    raku --doc=HTML input.raku > output.html
    =end code

    Rendering options for the renderering module cam be passed via the PODRENDER Environment variable, Eg.
    =begin code :lang<shell>
    PODRENDER='NoTOC NoMETA NoGloss NoFoot' raku --doc=HTML input.raku > output.html
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

    =head Standalone usage
    Inside a raku program, for a work flow that assumes the output as HTML snippets (as in a test file,
    or for a sequence of pod-trees that will be stitched together in a single file).

    =begin code :lang<raku>
        use Pod::To::HTML;
        # for repeated pod trees to be output as a single page or html snippets (as in a test file)
        my $renderer = Pod::To::HTML.processor(:name<Optional name defaults to UNNAMED>);
        # processor() actually returns a ProcessedPod instance. More details on parameters and functions there
        ... # later

        =begin pod
            some pod
        =end pod

        say 'The rendered pod is: ', $renderer.render-block( $=pod );

        =begin pod

            another fact-filled assertion

        =end pod

        say 'The next pod snippet is: ', $renderer.render-block( $=pod[1] );
        # note that all the pod in a file is collected into a 'pod-tree', which is an array of pod blocks. Hence
        # to obtain the last Pod block before a statement, as here, we need the latest addition to the pod tree.

        # later and perhaps after many pod statements, each of which must be processed through pod-block

        my $output-string = $renderer.source-wrap;

        # will return an HTML string containing the body of all the pod items, TOC, Glossary and Footnotes.
        # If there are headers in the accumulated pod, then a TOC will be generated and included
        # if there are X<> type references in the accumulated pod, then a Glossary will be generated and included

        $renderer.file-wrap(:output-file<some-useful-name>, :ext<html>);
        # first .source-wrap is called and then output to a file.
        # if ext is missing, 'html' is used
        # if C<some-useful-name> is missing, C<name> is used, which defaults to C<UNNAMED>
        # C<some-useful-name> could include a valid path.

    =end code

    Inside a raku program for an application that assumes each file is to be output as a separate html file

    =begin code :lang<raku>
        use Pod::To::HTML;
        my Pod::To::HTML $p .= processor;
        my %pod-input; # key is the path-name for the output file, value is a Pod::Block
        my @processed;
        # ... populate @pod-input, eg from a document cache
        my $counter = 1; # a counter to illustrate how to change output file name

        for %pod-input.kv -> $nm, $pd {
            with $p {
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
                @processed.append: $p.delete-pod-structure; # beware, pod-structure also deletes body, toc, glossary, etc contents
            }
        }
        # each instance of @processed will have TOC, Glossary and Footnote arrays that can be combined in some way
        for @processed {
            # each file has been written, but now process the whole collection data and write collection files.
        }
        # code to write global TOC and Glossary html files.
    =end code

=head CSS
        A minimal CSS is provided for the default templates and is placed in a <style>...</style> container.

        Two variables C<:css> and C<:src> are provided to customise the loading of css for the 'source-wrap' template provided here.
        These can be specified as arguments to C<processor>.

        If the B<source-wrap> template is over-ridden with a custom template using C<replace-template>, these variables will not
        have any effect because C<replace-template> is a C<ProcessedPod> method.

        If C<:css> is specified, then C<:src> must be specified.

=head2 CSS Load
        =begin code :lang<raku>
            use Pod::To::HTML;
            my Pod::To::HTML $processor = $pd.processor(:css<link>, :src('assets/pod.css') );
        =end code

        The contents of path/to/custom.css are slurped into a C< <style> > container by source-wrap.

        This is similar to the default action of the module, except that the pod.css file is in the module repository.

=head2 CSS Link
        Normally, when HTML is served a separate CSS file is loaded from a path on the server, or an http/https link.
        =begin code :lang<raku>
            use Pod::To::HTML;
            my Pod::To::HTML $processor = $pd.processor(:css<link>, :src('https:/somedomain.dom/assets/pod.css') );
        =end code

        This generates a <link> container in C< <head>...</head> >
        viz. C< <link rel="stylesheet" type="text/css" href="' ~ $!css-link ~ '" media="screen" title="default" /> >

=head Miscellaneous
        In the contents, headers can be prefixed with their header levels in the form 1.2.4

        The default separator (.) can be changed by setting (eg to _) as :counter-separator<_>

        The header levels can be omitted by setting :no-counters

=end pod

unit class Pod::To::HTML;

class X::ProcessedPod::HTML::InvalidCSS::NoSpec is Exception {
    method message() { "If :css is supplied to processor method, so must :src" }
}
class X::ProcessedPod::HTML::InvalidCSS::BadSource is Exception {
    has $.fn;
    method message() { "$.fn does not exist as a text file" }
}
class X::ProcessedPod::HTML::InvalidCSS::BadType is Exception {
    has $.type;
    method message() { "Only 'load' or 'link' acceptable, got '$.type'" }
}

use ProcessedPod;
our $css-text = '<style>' ~ %?RESOURCES<pod.css>.slurp ~ '</style>'  ;

method render($pod-tree) {
    state $rv;
    return $rv with $rv;
    # Some implementations of raku/perl6 called the classes render method twice,
    # so it's necessary to prevent the same work being done repeatedly

    my ProcessedPod $pp .= new(
        :tmpl(self.html-templates),
        :name($*PROGRAM-NAME)
    );
    # takes the pod tree and wraps it in HTML.
    $pp.process-pod($pod-tree);
    # Outputs a string that describes a html page
    $rv = $pp.source-wrap;
    # and store response so its not re-calculated
}

method processor( :$css, :$src ) {
    with $css {
        X::ProcessedPod::HTML::InvalidCSS::NoSpec.new.throw and return Nil without $src;
        if $css eq 'load' {
            X::ProcessedPod::HTML::InvalidCSS::BadSource.new(:fn($src)).throw and return Nil
                unless $src.IO.f;
            $css-text = '<style>' ~ $src.IO.slurp ~ '</style>';
        }
        elsif $css eq 'link' {
            $css-text = '<link rel="stylesheet"  type="text/css" href="' ~ $src ~ '" media="screen" title="default" />'
        }
        else {
            X::ProcessedPod::HTML::InvalidCSS::BadType.new(:type($css)).throw;
            return Nil
        }
    }
    my ProcessedPod $pp .= new(:tmpl(self.html-templates))
}

method html-templates {
    %(
        # templates that are used by process-pod
        # note that verbatim V<> does not have its own format because it affects what is inside it (see POD documentation)
        :escaped<{{ contents }}>,
        :raw<{{{ contents }}}>,

        'block-code' => q:to/TEMPL/,
            <pre class="pod-block-code{{# addClass }} {{ addClass }}{{/ addClass}}">
            {{# contents }}{{{ contents }}}{{/ contents }}</pre>
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
            </section>
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
        'source-wrap' => q:to/TEMPL1/ ~ $css-text ~ q:to/TEMPL2/,
            <!doctype html>
            <html lang="en">
                <head>
                    <title>{{ title }}</title>
                    <meta charset="UTF-8" />
            TEMPL1
                {{# metadata }}{{{ metadata }}}{{/ metadata }}
                </head>
                <body class="pod">
                    <div class="toc-glossary">
                    {{# toc }}{{{ toc }}}{{/ toc }}
                    {{# glossary }}{{{ glossary }}}{{/ glossary }}
                    </div>
                    <div class="pod-body{{^ toc }} no-toc{{/ toc }}">
                        {{{ body }}}
                    </div>
                    {{# footnotes }}{{{ footnotes }}}{{/ footnotes }}
                    {{# path }}
                    <footer>Rendered from {{ path }}{{/ path }}
                    {{# renderedtime }} at {{ renderedtime }}{{/ renderedtime }}{{# path }}
                    </footer>
                    {{/ path }}
                </body>
            </html>
            TEMPL2

        'footnotes' => q:to/TEMPL/,
            <div class="footnotes">
                <ol>{{# notes }}
                    <li id="{{ fnTarget }}">{{{ text }}}<a class="footnote" href="#{{ retTarget }}"> « Back »</a></li>
                    {{/ notes }}
                </ol>
            </div>
            TEMPL

        'glossary' => q:to/TEMPL/,
                 <table id="Glossary">
                    <caption>Glossary</caption>
                    <tr><th>Term</th><th>Section Location</th></tr>
                    {{# glossary }}
                    <tr class="glossary-defn-row">
                        <td class="glossary-defn">{{{ text }}}</td><td></td></tr>
                        {{# refs }}<tr class="glossary-place-row"><td></td><td class="glossary-place"><a href="#{{ target }}">{{{ place }}}</a></td></tr>{{/ refs }}
                    {{/ glossary }}
                </table>
            TEMPL

        'meta' => q:to/TEMPL/,
                 {{# meta }}
                    <meta name="{{ name }}" value="{{ value }}" />
                {{/ meta }}
            TEMPL

        'toc' => q:to/TEMPL/,
                <table id="TOC">
                    <caption>Table of Contents</caption>
                    {{# toc }}
                    <tr class="toc-level-{{ level }}">
                        <td class="toc-text"><a href="#{{ target }}">{{# counter }}<span class="toc-counter">{{ counter }}</span>{{/ counter }} {{ text }}</a></td>
                    </tr>
                    {{/ toc }}
                </table>
            TEMPL
    )
}