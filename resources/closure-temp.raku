use ProcessedPod;
my $camelia-svg = 'camelia-svg';
my $css-text = 'css-text';
my $favicon-bin = 'favicon-bin';
%(
# the following are extra for HTML files and are needed by the render (class) method
# in the source-wrap template.
    'escaped' => sub ( $s ) { $s.trans: qw｢ <    >    &     " ｣ => qw｢ &lt; &gt; &amp; &quot; ｣ },
    'raw' => sub ( %prm, %tml ) { (%prm<contents> // '') },
    'camelia-img' => sub ( %prm, %tml ) { $camelia-svg },
    'css-text' => sub ( %prm, %tml ) { $css-text },
    'favicon' => sub ( %prm, %tml ) { '<link href="data:image/x-icon;base64,' ~ $favicon-bin ~ '" rel="icon" type="image/x-icon" />' },
    'block-code' => sub ( %prm, %tml ) {
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
                ~ '</dt><dd>'
                ~ (%prm<contents> // '')
                ~ '</dd>'
    },
    'dlist-end' => sub ( %prm, %tml ) { "\n</dl>" },
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
                ~ (%prm<local> ?? '.html'!! '')
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
    'title' => sub ( %prm, %tml) {
        '<h1 class="title" id="' ~ %tml<escaped>(%prm<title-target>) ~ '">' ~ %prm<title> ~ '</h1>'
    },
    'subtitle' => sub ( %prm, %tml ) { '<div class="subtitle">' ~ %prm<subtitle> ~ '</div>' },
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
                        ~ %tml<escaped>( .<target> )
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
                ~ %tml<favicon>(%prm, %tml)
                ~ (%prm<metadata> // '')
                ~ (  ( %prm<css>.defined and %prm<css> ne '' )
                ?? ('<link rel="stylesheet" href="' ~ %prm<css> ~ '">')
                !! %tml<css-text>(%prm, %tml)
        )
                ~ (%prm<head> // '')
                ~ "\</head>\n"
    },
    'header' => sub ( %prm,%tml) {
        '<header>' ~ %tml<camelia-img>(%prm, %tml) ~ %tml<title>(%prm, %tml) ~ '</header>'
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
