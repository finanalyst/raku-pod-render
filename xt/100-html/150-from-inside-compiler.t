use Test;

constant No_SHELL_TEST = ?%*ENV<NO_SHELL_TEST>;

if ! No_SHELL_TEST {
    plan 15;
    diag 'PODRENDER unset';
    my $p = run 'raku', '-Ilib', '--doc=HTML', 'xt/rend-test-file.raku', :out;
    my $rv = $p.out.slurp(:close);

    like $rv, / .*? '<html' .*? '>' .*? '<body' .*? '>' .*? 'Some pod' .*? '</body>' .*? '</html>' /, 'Pod::To::HTML2 works with compiler';

    like $rv, /
        'id="Glossary"'
        /, 'glossary is rendered';

    like $rv, /
        '<meta name="author" value="An author' .+ '"' .+ '/>'
        .+ '<meta name="summary" value="This page' .+ '/>'
        /, 'meta is rendered';

    like $rv,
        /
        'id="TOC"'
        /
        , 'rendered TOC';

    like $rv, /
        'id="Footnotes"'
        /, 'footnotes rendered';

    diag 'PODRENDER="no-toc"';
    $p = shell 'PODRENDER="no-toc" raku -Ilib --doc=HTML2 xt/rend-test-file.raku', :out;
    $rv = $p.out.slurp(:close);

    like $rv, / .*? '<html' .*? '>' .*? '<body' .*? '>' .*? 'Some pod' .*? '</body>' .*? '</html>' /, 'Pod::To::HTML2 works with compiler';

    like $rv, /
        'id="Glossary"'
        /, 'glossary is rendered';

    like $rv, /
        '<meta name="author" value="An author' .+ '"' .+ '/>'
        .+ '<meta name="summary" value="This page' .+ '/>'
        /, 'meta is rendered';

    unlike $rv,
        /
        'id="TOC"'
        /
        , 'not rendered TOC';

    like $rv, /
        'id="Footnotes"'
        /, 'footnotes rendered';

    diag 'PODRENDER="no-toc no-glos"';
    $p = shell 'PODRENDER="no-toc no-glos" raku -Ilib --doc=HTML2 xt/rend-test-file.raku', :out;
    $rv = $p.out.slurp(:close);

    like $rv, / .*? '<html' .*? '>' .*? '<body' .*? '>' .*? 'Some pod' .*? '</body>' .*? '</html>' /, 'Pod::To::HTML2 works with compiler';

    unlike $rv, /
        'id="Glossary"'
            /, 'glossary not rendered';

    like $rv, /
        '<meta name="author" value="An author' .+ '"' .+ '/>'
            .+ '<meta name="summary" value="This page' .+ '/>'
            /, 'meta is rendered';

    unlike $rv,
            /
            'id="TOC"'
            /
            , 'not rendered TOC';

    like $rv, /
        'id="Footnotes"'
            /, 'footnotes rendered';
}
else
{
    plan 1;
    skip-rest "Repeat these tests with prove, eg.  PROVE_TEST=1 prove -ve 'raku -Ilib' xt/100-html/150*";
}

done-testing;
