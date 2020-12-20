use Test;

constant No_SHELL_TEST = ?%*ENV<NO_SHELL_TEST>;

if ! No_SHELL_TEST {
    plan 15;
    diag 'PODRENDER unset';
    my $p = run 'raku', '-Ilib', '--doc=HTML', 'xt/rend-test-file.raku', :out;
    my $rv = $p.out.slurp.subst(/\s+/,' ',:g).trim;;
    $p.out.close;

    like $rv, / .*? '<html' .*? '>' .*? '<body' .*? '>' .*? 'Some pod' .*? '</body>' .*? '</html>' /, 'Pod::To::HTML works with compiler';

    like $rv, /
        '<table id="Glossary">'
        \s* '<caption>Glossary</caption>'
        /, 'glossary is rendered';

    like $rv, /
        '<meta name="author" value="An author' .+ '"' .+ '/>'
        .+ '<meta name="summary" value="This page' .+ '/>'
        /, 'meta is rendered';

    like $rv,
        /
        '<table id="TOC">'
                \s* '<caption>Table of Contents</caption>'
                \s* '<tr class="toc-level-2">'
                \s* '<td class="toc-text">'
                \s* '<a href="#This_is_a_heading">'
                .+ 'This is a heading</a>'
                \s* '</td>'
                \s* '</tr>'
                \s* '</table>'
        /
        , 'rendered TOC';

    like $rv, /
        '<div class="footnotes">'
        \s* '<ol>'
        \s* '<li id="fn' .+ '">A footnote<a class="footnote" href="#fnret' .+ '"> « Back »</a></li>'
        \s* '<li' .+ '>next to a word<a'
        .+
        '</ol>'
        \s* '</div>'
        /, 'footnotes rendered';

    diag 'PODRENDER="no-toc"';
    $p = shell 'PODRENDER="no-toc" raku -Ilib --doc=HTML xt/rend-test-file.raku', :out;
    $rv = $p.out.slurp.subst(/\s+/,' ',:g).trim;;
    $p.out.close;

    like $rv, / .*? '<html' .*? '>' .*? '<body' .*? '>' .*? 'Some pod' .*? '</body>' .*? '</html>' /, 'Pod::To::HTML works with compiler';

    like $rv, /
        '<table id="Glossary">'
        \s* '<caption>Glossary</caption>'
        /, 'glossary is rendered';

    like $rv, /
        '<meta name="author" value="An author' .+ '"' .+ '/>'
        .+ '<meta name="summary" value="This page' .+ '/>'
        /, 'meta is rendered';

    unlike $rv,
        /
        '<table id="TOC">'
                \s* '<caption>'
                \s* '<h2 id="TOC_Title">Table of Contents</h2></caption>'
        /
        , 'not rendered TOC';

    like $rv, /
        '<div class="footnotes">'
        \s* '<ol>'
        \s* '<li id="fn' .+ '">A footnote<a class="footnote" href="#fnret' .+ '"> « Back »</a></li>'
        \s* '<li' .+ '>next to a word<a'
        .+
        '</ol>'
        \s* '</div>'
        /, 'footnotes rendered';

    diag 'PODRENDER="no-toc no-glos"';
    $p = shell 'PODRENDER="no-toc no-glos" raku -Ilib --doc=HTML xt/rend-test-file.raku', :out;
    $rv = $p.out.slurp.subst(/\s+/,' ',:g).trim;;
    $p.out.close;

    like $rv, / .*? '<html' .*? '>' .*? '<body' .*? '>' .*? 'Some pod' .*? '</body>' .*? '</html>' /, 'Pod::To::HTML works with compiler';

    unlike $rv, /
        '<table id="Glossary">'
            \s* '<caption>Glossary</caption>'
            /, 'glossary not rendered';

    like $rv, /
        '<meta name="author" value="An author' .+ '"' .+ '/>'
            .+ '<meta name="summary" value="This page' .+ '/>'
            /, 'meta is rendered';

    unlike $rv,
            /
            '<table id="TOC">'
                    \s* '<caption>'
                    \s* 'Table of Contents/caption>'
            /
            , 'not rendered TOC';

    like $rv, /
        '<div class="footnotes">'
            \s* '<ol>'
            \s* '<li id="fn' .+ '">A footnote<a class="footnote" href="#fnret' .+ '"> « Back »</a></li>'
            \s* '<li' .+ '>next to a word<a'
            .+
            '</ol>'
            \s* '</div>'
            /, 'footnotes rendered';
}
else
{
    plan 1;
    skip-rest "Repeat these tests with prove, eg.  PROVE_TEST=1 prove -ve 'raku -Ilib' xt/100-html/150*";
}

done-testing;
