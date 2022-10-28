#!/usr/bin/env raku
use v6.d;
%(
    latex => sub (%prm, %tml) {
        #remove <p> and </p>
        my $data = %prm<contents>.subst(/^\<p\>/, '');
        $data .=subst(/\<\/p\> \s* $/, '');
        # de-escape data
        $data .= trans(qw｢ &lt; &gt; &amp; &quot; ｣ => qw｢ <    >    &     " ｣);
        qq:to/LATEX/;
            <div class="latex-render">
            <img src="https://latex.codecogs.com/svg.image?{ $data }" />
            <img class="logo" src="https://www.codecogs.com/images/poweredbycodecogs.png" border="0" alt="CodeCogs - An Open Source Scientific Library"></a>
            </div>
            LATEX
    },
)