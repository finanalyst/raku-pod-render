use Test;
use JSON::Fast;
plan 1;
my $orig-dir = 't-legacy';
for <class test multi> { ( "$orig-dir/$_.pod6").IO.copy: "t/$_.pod6" }
"t/templates".IO.mkdir;
"$orig-dir/templates/main.mustache".IO.copy: "t/templates/main.mustache";

ok 1, 'creating html templates to match original hard coded html of original P2HTML';
'html-templates.raku'.IO.spurt(q:to/CODE/);
    use ProcessedPod;
    my class Pseudo {
        has $.contents
    };
    %(
        'escaped' => sub ( $s ) {
                if $s and $s ne ''
                { $s.trans( [ q{&},     q{<},    q{>},    q{"},      q{'},      q{ }      ] =>
                          [ q{&amp;}, q{&lt;}, q{&gt;}, q{&quot;}, q{&#39;} , q{&nbsp;} ] ) }
                else { '' }
        },
        'id-escaped' => sub ( $s ) {
                if $s and $s ne ''
                { $s.trans( [ q{&},     q{<},    q{>},    q{"},      q{ }      ] =>
                          [ q{&amp;}, q{&lt;}, q{&gt;}, q{&quot;}, q{&nbsp;} ] ) }
                else { '' }
        },
        'raw' => sub ( %prm, %tml ) { (%prm<contents> // '') },
        'block-code' => sub ( %prm, %tml ) {
            if %*POD2HTML-CALLBACKS and %*POD2HTML-CALLBACKS<code>.defined {
                my $node = Pseudo.new( :contents(%prm<contents>) );
                if %*POD2HTML-CALLBACKS<code> -> &cb {
                    cb :$node, default => sub ($node) {
                        $node.contents
                    }
                }
            }
            '<pre class="pod-block-code">'
                    ~ (%prm<contents> // '')
                    ~ '</pre>'
        },
        'comment' => sub ( %prm, %tml ) { '<!-- ' ~ (%prm<contents> // '') ~ ' -->' },
        'declarator' => sub ( %prm, %tml ) {
            '<a name="' ~ %tml<escaped>(%prm<target> // '')
                    ~ '"></a><article><code class="pod-code-inline">'
                    ~ ( %prm<code> // '') ~ '</code>' ~ (%prm<contents> // '') ~ '</article>'
        },
        'dlist-start' => sub ( %prm, %tml ) { "<dl>\n" },
        'defn' => sub ( %prm, %tml ) {
            '<dt>'
                    ~ %tml<escaped>(%prm<term> // '')
                    ~ '</dt><dd><p>'
                    ~ (%prm<contents> // '')
                    ~ '</p></dd>'
        },
        'dlist-end' => sub ( %prm, %tml ) { "\n</dl>\n" },
        'format-b' => gen-closure-template('strong'),
        'format-c' => gen-closure-template('code'),
        'format-i' => gen-closure-template('em'),
        'format-k' => gen-closure-template('kbd'),
        'format-r' => gen-closure-template('var'),
        'format-t' => gen-closure-template('samp'),
        'format-u' => gen-closure-template('u'),
        'para' => gen-closure-template('p'),
        'format-l' => sub ( %prm, %tml ) {
            '<a href="'
                    ~ (%prm<internal> ?? '#' !! '')
                    ~ %prm<target>
                    ~ '">'
                    ~ (%prm<contents> // '')
                    ~ '</a>'
        },
        'format-n' => sub ( %prm, %tml ) {
            '<sup><a name="'
                    ~ %tml<escaped>(%prm<retTarget>)
                    ~ '" href="#' ~ %tml<escaped>(%prm<fnTarget>)
                    ~ '">[' ~ %tml<escaped>(%prm<fnNumber>)
                    ~ "]</a></sup>\n"
        },
        'format-p' => sub ( %prm, %tml ) {
            '<div><pre>'
                    ~ (%prm<contents> // '').=trans(['<pre>', '</pre>'] => ['&lt;pre&gt;', '&lt;/pre&gt;'])
                    ~ "</pre></div>\n"
        },
        'format-x' => sub ( %prm, %tml ) {
            '<a name="' ~ (%prm<target> // '') ~ '">'
            ~ ( ( %prm<text>.defined and %prm<text> ne '' ) ?? '<span class="glossary-entry">' ~ %prm<text> ~ '</span>' !! '')
            ~ '</a>'
        },
        'heading' => sub ( %prm, %tml ) {
            '<h' ~ (%prm<level> // '1')
                    ~ ' id="'
                    ~ %tml<id-escaped>(%prm<target>)
                    ~ '"><a class="u" href="#'
                    ~ %tml<escaped>(%prm<top>)
                    ~ '" title="go to top of document">'
                    ~ (( %prm<text>.defined && %prm<text> ne '') ?? %prm<text> !! '')
                    ~ '</a></h'
                    ~ (%prm<level> // '1')
                    ~ ">\n"
        },
        'image' => sub ( %prm, %tml ) { '<img src="' ~ (%prm<src> // 'path/to/image') ~ '"'
                ~ ' width="' ~ (%prm<width> // '100px') ~ '"'
                ~ ' height="' ~ (%prm<height> // 'auto') ~ '"'
                ~ ' alt="' ~ (%prm<alt> // 'XXXXX') ~ '">'
        },
        'item' => sub ( %prm, %tml ) { '<li>' ~ (%prm<contents> // '') ~ "</li>\n" },
        'list' => sub ( %prm, %tml ) {
            "<ul>\n"
                    ~ %prm<items>.join
                    ~ "</ul>\n"
        },
        'named' => sub ( %prm, %tml ) {
            "<section>\n<h1>"
                    ~ (( %prm<name>.defined && %prm<name> ne '' ) ?? %prm<name> !! '')
                    ~ "</h1>\n"
                    ~ (%prm<contents> // '')
                    ~ "\n</section>\n"
        },
        'output' => sub ( %prm, %tml ) { '<pre class="pod-output">' ~ (%prm<contents> // '') ~ '</pre>' },
        'pod' => sub ( %prm, %tml ) {
            (%prm<class> ?? ('<span class="' ~ %prm<class> ~ '">') !! '' )
            ~ (%prm<contents> // '')
            ~ (%prm<tail> // '')
            ~ (%prm<class> ?? '</span>' !! '' )
        },
        'table' => sub ( %prm, %tml ) {
            '<table class="pod-table'
                    ~ ( ( %prm<class>.defined and %prm<class> ne '' ) ?? (' ' ~ %tml<escaped>(%prm<class>)) !! '')
                    ~ '">'
                    ~ ( ( %prm<caption>.defined and %prm<caption> ne '' ) ?? ('<caption>' ~ %prm<caption> ~ '</caption>') !! '')
                    ~ ( ( %prm<headers>.defined and %prm<headers> ne '' ) ??
            ("\t<thead>\n"
                    ~ [~] %prm<headers>.map({ "\t\t<tr><th>" ~ .<cells>.join('</th><th>') ~ "</th></tr>\n"})
                            ~ "\t</thead>"
            ) !! '')
                    ~ "\t<tbody>\n"
                    ~ ( ( %prm<rows>.defined and %prm<rows> ne '' ) ??
            [~] %prm<rows>.map({ "\t\t<tr><td>" ~ .<cells>.join('</td><td>') ~ "</td></tr>\n" })
            !! '')
                    ~ "\t</tbody>\n"
                    ~ "</table>\n"
        },
        'title' => sub ( %prm, %tml) {
                if %prm<title>:exists and %prm<title> ne '' {
                    '<h1 class="title"'
                     ~ ((%prm<title-target>:exists and %prm<title-target> ne '')
                            ?? ' id="' ~ %tml<escaped>(%prm<title-target>) !! '' ) ~ '">'
                     ~ %prm<title> ~ '</h1>'
                }
                else { '' }
        },
        'subtitle' => sub ( %prm, %tml ) {
            if %prm<subtitle>:exists and %prm<subtitle> ne '' {
                '<div class="subtitle">' ~ %prm<subtitle> ~ '</div>' }
            else { '' }
        },
        'source-wrap' => sub ( %prm, %tml ) {
            "<!doctype html>\n"
                    ~ '<html lang="' ~ ( ( %prm<lang>.defined and %prm<lang> ne '' ) ?? %tml<escaped>(%prm<lang>) !! 'en') ~ "\">\n"
                    ~ %tml<head-block>(%prm, %tml)
                    ~ "\t<body class=\"pod\">\n"
                    ~ %tml<header>(%prm, %tml)
                    ~ (( %prm<toc>.defined or %prm<glossary>.defined ) ?? '<div class="toc-glossary">' !! '')
                    ~ (%prm<toc> // '')
                    ~ (%prm<glossary> // '')
                    ~ (( %prm<toc>.defined or %prm<glossary>.defined ) ?? '</div>' !! '')
                    ~ %tml<subtitle>(%prm, %tml)
                    ~ '<div class="pod-body' ~ (( %prm<toc>.defined and %prm<toc> ne '' ) ?? '' !! ' no-toc') ~ '">'
                    ~ (%prm<body> // '')
                    ~ "\t\t</div>\n"
                    ~ (%prm<footnotes> // '')
                    ~ %tml<footer>(%prm, %tml)
                    ~ "\n\t</body>\n</html>\n"
        },
        'footnotes' => sub ( %prm, %tml ) {
            with %prm<notes> {
                "<div class=\"footnotes\">\n<ol>"
                        ~ [~] .map({ '<li id="' ~ %tml<escaped>($_<fnTarget>) ~ '">'
                        ~ ($_<text> // '')
                        ~ '<a class="footnote" href="#'
                        ~ %tml<escaped>($_<retTarget>)
                        ~ "\"> « Back »</a></li>\n"
                })
                        ~ "\n</ol>\n</div>\n"
            }
            else { '' }
        },
        'glossary' => sub ( %prm, %tml ) {
            if %prm<glossary>.defined {
                "<table id=\"Glossary\">\n<caption>Glossary</caption>\n<tr><th>Term</th><th>Section Location</th></tr>\n"
                        ~ [~] %prm<glossary>.map({ "<tr class=\"glossary-defn-row\">\n"
                        ~ '<td class="glossary-defn">'
                        ~ ($_<text> // '')
                        ~ "</td><td></td></tr>\n"
                        ~ [~] $_<refs>.map({
                            '<tr class="glossary-place-row"><td></td><td class="glossary-place"><a href="#'
                                    ~ %tml<escaped>($_<target>)
                                    ~ '">'
                                    ~ ($_<place>.defined ?? $_<place> !! '')
                                    ~ "</a></td></tr>\n"
                        })
                })
                        ~ "\n</table>\n"
            }
            else { '' }
        },
        'meta' => sub ( %prm, %tml ) {
            if %prm<meta>.defined {
                [~] %prm<meta>.map({
                    '<meta name="' ~ %tml<escaped>( .<name> )
                            ~ '" value="' ~ %tml<escaped>( .<value> )
                            ~ "\" />\n"
                })
            }
            else { '' }
        },
        'toc' => sub ( %prm, %tml ) {
            if %prm<toc>.defined {
                "<table id=\"TOC\">\n<caption>Table of Contents</caption>\n"
                        ~ [~] %prm<toc>.map({
                    '<tr class="toc-level-' ~ .<level> ~ '">'
                            ~ '<td class="toc-text"><a href="#'
                            ~ %tml<id-escaped>( .<target> )
                            ~ '">'
                            ~ ( $_<counter>.defined ?? ('<span class="toc-counter">' ~ %tml<escaped>( .<counter> ) ~ '</span>') !! '' )
                            ~ ' ' ~ %tml<escaped>(  $_<text> // '' )
                            ~ "</a></td></tr>\n"
                })
                        ~ "</table>\n"
            }
            else { '' }
        },
        'head-block' => sub ( %prm, %tml ) {
            "\<head>\n"
                    ~ '<title>' ~ %tml<escaped>(%prm<title>) ~ "\</title>\n"
                    ~ '<meta charset="UTF-8" />' ~ "\n"
                    ~ (%prm<metadata> // '')
                    ~ (  ( %prm<css>.defined and %prm<css> ne '' )
                    ?? ('<link rel="stylesheet" href="' ~ %prm<css> ~ '">')
                    !! '' )
                    ~ (%prm<head> // '')
                    ~ "\</head>\n"
        },
        'header' => sub ( %prm,%tml) {
            '<header>' ~ %tml<title>(%prm, %tml) ~ '</header>'
        },
        'footer' => sub ( %prm, %tml ) {
            '<footer><div>Rendered from <span class="path">'
                    ~ (( %prm<path>.defined && %prm<path> ne '') ?? %tml<escaped>(%prm<path>) !! 'Unknown')
                    ~ '</span></div>'
                    ~ '<div>at <span class="time">'
                    ~ (( %prm<renderedtime>.defined && %prm<path> ne '') ?? %tml<escaped>(%prm<renderedtime>) !! 'a moment before time began!?')
                    ~ '</span></div>'
                    ~ '</footer>'
        },
    );
    CODE
