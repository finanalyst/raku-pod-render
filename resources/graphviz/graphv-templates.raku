#!/usr/bin/env raku
use v6.d;
%(
    graphviz => sub (%prm, %tml) {
        #remove <p> and </p>
        my $data = %prm<contents>.subst(/^\<p\>/, '');
        $data .=subst(/\<\/p\> \s* $/, '');
        # de-escape data
        $data .= trans(qw｢ &lt; &gt; &amp; &quot; ｣ => qw｢ <    >    &     " ｣);
        my $proc = Proc::Async.new(:w, 'dot', '-Tsvg');
        my $proc-rv;
        my $proc-err;
        $proc.stdout.tap(-> $d { $proc-rv ~= $d });
        $proc.stderr.tap(-> $v { $proc-err ~= $v });
        my $promise = $proc.start;
        $proc.put($data);
        $proc.close-stdin;
        try {
            await $promise;
            CATCH {
                default {}
            }
        }
        my $rv = "\n"~'<div class="graphviz">';
        if $proc-rv { $rv ~= $proc-rv }
        elsif $proc-err {
           $rv ~= '<div style="color: red">'
            ~ $proc-err.subst(/^ .+? 'tdin>:' \s*/, '') ~ '</div>'
            ~ '<div>Graph input was <div style="color: green">' ~ $data ~ '</div></div>'
        }
        $rv ~= '</div>'
    }
);