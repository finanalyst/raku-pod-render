#!/usr/bin/env raku
use v6.d;

%(
# the following are extra for HTML files and are needed by the render (class) method
# in the source-wrap template.
    '_templater' => 'RakuClosureTemplater',
    'escaped' => sub ($s) {
        if $s and $s ne ''
        { $s.trans(qw｢ <    >    &     " ｣ => qw｢ &lt; &gt; &amp; &quot; ｣) }
        else { '' }
    },
    'raw' => sub ( %prm, %tml ) { (%prm<contents> // '') },
    'camelia-img' => sub ( %prm, %tml ) { '<camelia />' },
    'css' => sub ( %prm, %tml ) { '<style>debug</style>' },
    'head' => sub ( %prm, %tml ) { '' },
    'favicon' => sub ( %prm, %tml ) { '<meta>NoIcon</meta>' },
    'block-code' => sub ( %prm, %tml ) {
        if %prm<highlighted>:exists {
            # a highlighter will add its own classes to the <pre> container
            %prm<highlighted>
        }
        else {
            '<pre class="pod-block-code">'
                ~ %prm<contents>
                ~ '</pre>'
        }
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
                ~ '</dt><dd>'
                ~ (%prm<contents> // '')
                ~ '</dd>'
    },
    'dlist-end' => sub ( %prm, %tml ) { "\n</dl>" },
    'format-b' => sub ( %prm, %tml --> Str ) {
		'<strong>' ~ (%prm<contents> // '') ~ '</strong>'
	},
    'format-c' => sub ( %prm, %tml --> Str ) {
		'<code>' ~ (%prm<contents> // '') ~ '</code>'
	},
    'format-i' => sub ( %prm, %tml --> Str ) {
		'<em>' ~ (%prm<contents> // '') ~ '</em>'
	},
    'format-k' => sub ( %prm, %tml --> Str ) {
		'<kbd>' ~ (%prm<contents> // '') ~ '</kbd>'
	},
    'format-r' => sub ( %prm, %tml --> Str ) {
		'<var>' ~ (%prm<contents> // '') ~ '</var>'
	},
    'format-t' => sub ( %prm, %tml --> Str ) {
		'<samp>' ~ (%prm<contents> // '') ~ '</samp>'
	},
    'format-u' => sub ( %prm, %tml --> Str ) {
		'<u>' ~ (%prm<contents> // '') ~ '</u>'
	},
    'para' => sub ( %prm, %tml --> Str ) {
		'<p>' ~ (%prm<contents> // '') ~ '</p>'
	},
    'format-l' => sub ( %prm, %tml ) {
        # transform a local file with an internal target
        my $trg = %prm<target>;
        if %prm<local> {
            if $trg ~~ / (<-[#]>+) '#' (.+) $ / {
                $trg = "$0\.html\#$1";
            }
            else {
                $trg ~= '.html'
            }
        }
        elsif %prm<internal> {
            $trg = "#$trg"
        }
        '<a href="'
                ~ $trg
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
        '<a name="' ~ (%prm<target> // '') ~ '"></a>'
        ~ ( ( %prm<text>.defined and %prm<text> ne '' ) ?? '<span class="glossary-entry">' ~ %prm<text> ~ '</span>' !! '')
    },
    'heading' => sub ( %prm, %tml ) {
        '<h' ~ (%prm<level> // '1')
                ~ ' id="'
                ~ %tml<escaped>(%prm<target>)
                ~ '"><a href="#'
                ~ %tml<escaped>(%prm<top>)
                ~ '" class="u" title="go to top of document">'
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
        "<section>\n<h"
                ~ (%prm<level> // '1') ~ ' id="'
                ~ %tml<escaped>(%prm<target>) ~ '"><a href="#'
                ~ %tml<escaped>(%prm<top> // '')
                ~ '" class="u" title="go to top of document">'
                ~ (( %prm<name>.defined && %prm<name> ne '' ) ?? %prm<name> !! '')
                ~ '</a></h' ~ (%prm<level> // '1') ~ ">\n"
                ~ (%prm<contents> // '')
                ~ (%prm<tail> // '')
                ~ "\n</section>\n"
    },
    'output' => sub ( %prm, %tml ) { '<pre class="pod-output">' ~ (%prm<contents> // '') ~ '</pre>' },
    'pod' => sub ( %prm, %tml ) {
        '<section name="'
                ~ %tml<escaped>(%prm<name> // '') ~ '">'
                ~ (%prm<contents> // '')
                ~ (%prm<tail> // '')
                ~ '</section>'
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
    'top-of-page' => sub ( %prm, %tml ) {
        if %prm<title-target>:exists and %prm<title-target> ne '' {
            '<div id="' ~ %tml<escaped>(%prm<title-target>) ~ '"></div>'
        }
        else { '' }
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
                ~ '<div class="pod-content">'
                ~ (( (%prm<toc>.defined and %prm<toc>.keys) or (%prm<glossary>.defined and %prm<glossary>.keys) ) ?? '<nav>' !! '')
                ~ (%prm<toc> // '')
                ~ (%prm<glossary> // '')
                ~ (( (%prm<toc>.defined and %prm<toc>.keys) or (%prm<glossary>.defined and %prm<glossary>.keys) ) ?? '</nav>' !! '')
                ~ %tml<top-of-page>(%prm, %tml)
                ~ %tml<subtitle>(%prm, %tml)
                ~ '<div class="pod-body' ~ (( %prm<toc>.defined and %prm<toc>.keys ) ?? '' !! ' no-toc') ~ '">'
                ~ (%prm<body> // '')
                ~ "\t\t</div>\n"
                ~ (%prm<footnotes> // '')
                ~ '</div>'
                ~ %tml<footer>(%prm, %tml)
                ~ "\n\t</body>\n</html>\n"
    },
    'footnotes' => sub ( %prm, %tml ) {
        with %prm<notes> {
            if %prm<notes>.elems {
                "<div id=\"_Footnotes\" class=\"footnotes\">\n<ul>"
                        ~ [~] .map({ '<li id="' ~ %tml<escaped>($_<fnTarget>) ~ '">'
                        ~ ('<span class="footnote-number">' ~ ($_<fnNumber> // '') ~ '</span>')
                        ~ ($_<text> // '')
                        ~ '<a class="footnote" href="#'
                        ~ %tml<escaped>($_<retTarget>)
                        ~ "\"> « Back »</a></li>\n"
                })
                        ~ "\n</ul>\n</div>\n"
            }
            else { '' }
        }
        else { '' }
    },
    'glossary' => sub ( %prm, %tml ) {
        if %prm<glossary>.defined and %prm<glossary>.keys {
            '<div id="_Glossary" class="glossary">' ~ "\n"
                    ~ '<div class="glossary-caption">Glossary</div>' ~ "\n"
                    ~ '<div class="glossary-defn header">Term explained</div><div class="header glossary-place">In section</div>'
                    ~ [~] %prm<glossary>.map({
                        '<div class="glossary-defn">'
                        ~ ($_<text> // '')
                        ~ '</div>'
                        ~ [~] $_<refs>.map({
                            '<div class="glossary-place"><a href="#'
                                    ~ %tml<escaped>($_<target>)
                                    ~ '">'
                                    ~ ($_<place>.defined ?? $_<place> !! '')
                                    ~ "</a></div>\n"
                        })
                })
                    ~ "</div>\n"
        }
        else { '' }
    },
    'meta' => sub ( %prm, %tml ) {
        with %prm<meta> {
            [~] %prm<meta>.map({
                '<meta name="' ~ %tml<escaped>( .<name> )
                        ~ '" value="' ~ %tml<escaped>( .<value> )
                        ~ "\" />\n"
            })
        }
        else { '' }
    },
    'toc' => sub ( %prm, %tml ) {
        if %prm<toc>.defined and %prm<toc>.keys {
            "<div id=\"_TOC\"><table>\n<caption>Table of Contents</caption>\n"
                    ~ [~] %prm<toc>.map({
                '<tr class="toc-level-' ~ .<level> ~ '">'
                        ~ '<td class="toc-text"><a href="#'
                        ~ %tml<escaped>( .<target> )
                        ~ '">'
                        ~ %tml<escaped>(  $_<text> // '' )
                        ~ "</a></td></tr>\n"
            })
                    ~ "</table></div>\n"
        }
        else { '' }
    },
    'head-block' => sub ( %prm, %tml ) {
        "\<head>\n"
                ~ '<title>' ~ %tml<escaped>(%prm<title>) ~ "\</title>\n"
                ~ '<meta charset="UTF-8" />' ~ "\n"
                ~ %tml<favicon>({}, {})
                ~ (%prm<metadata> // '')
                ~ %tml<css>( {}, {} )
                ~ %tml<head>( {}, {} )
                ~ "\</head>\n"
    },
    'header' => sub ( %prm,%tml) {
        '<header>' ~ %tml<camelia-img>(%prm, %tml) ~ '<h1 class="title">' ~ %prm<title> ~ '</h1></header>'
    },
    'footer' => sub ( %prm, %tml ) {
        '<footer><div>Rendered from <span class="path">'
                ~ ( ( %prm<path>.defined && %prm<path> ne '')
                    ??
                    %tml<escaped>(%prm<path>)
                    !!
                    %tml<escaped>(%prm<name>) )
                ~ '</span></div>'
                ~ '<div>at <span class="time">'
                ~ (( %prm<renderedtime>.defined && %prm<path> ne '') ?? %tml<escaped>(%prm<renderedtime>) !! 'a moment before time began!?')
                ~ '</span></div>'
                ~ '</footer>'
    },
);
