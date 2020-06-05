use Test;

plan 15;

my $p = run 'raku', '-Ilib', '--doc=HTML', 't/___-rend-test-file.raku', :out;
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
            \s* '<a href="#this_is_a_heading">'
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

$p = shell 'PODRENDER="no-toc" raku -Ilib --doc=HTML t/___-rend-test-file.raku', :out;
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

$p = shell 'PODRENDER="no-toc no-glos" raku -Ilib --doc=HTML t/___-rend-test-file.raku', :out;
$rv = $p.out.slurp.subst(/\s+/,' ',:g).trim;;
$p.out.close;

like $rv, / .*? '<html' .*? '>' .*? '<body' .*? '>' .*? 'Some pod' .*? '</body>' .*? '</html>' /, 'Pod::To::HTML works with compiler';

unlike $rv, /
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
                \s* 'Table of Contents/caption>'
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
done-testing;
