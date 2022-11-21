sub ($pp --> Positional) {
    my $css = '';
    my @links;
    my @adds;
    for $pp.plugin-datakeys {
        my $data = $pp.get-data($_);
        next unless $data ~~ Associative;
        if $data<css>:exists and $data<css> ~~ Str:D {
            my $file = ($data<path> ~ '/' ~ $data<css>).IO;
            $css ~= "\n" ~ $file.slurp
        }
        elsif $data<css-link>:exists and $data<css-link> ~~ Str:D {
            @links.append($data<css-link>)
        }
        elsif $data<add-css>:exists and $data<add-css> ~~ Str:D {
            @adds.push( ($data<path> , $data<add-css>) )
        }
        elsif $data<add-css>:exists and $data<add-css> ~~ Positional {
            @adds.append( ($data<path> , $_ ) ) for $data<add-css>.list
        }
    }
    my $template = '%( css => sub (%prm, %tml) {' ~ "\n";
    my $ln-st = '~ \'<link rel="stylesheet" type="text/css"';
    my $ln-end = '/>\' ~ "\n"' ~ "\n";
    my $dir-pre = 'asset_files';
    my $dir-post = 'css';
    my @move-dest;
    if $css {
        # remove any .ccs.map references in text as these are not loaded
        $css.subst-mutate(/ \n \N+ '.css.map' .+? $$/, '', :g);
        my $fn = 'rakudoc-extra.css';
        $fn.IO.spurt($css);
        $template ~= "$ln-st href=\"$dir-pre/$dir-post/$fn\" $ln-end" ;
        @move-dest.push: ( "$dir-post/$fn","$*CWD/$fn" );
    }
    for @adds {
        $template ~= "$ln-st href=\"$dir-pre/$dir-post/$_[1]\" $ln-end" ;
        @move-dest.push: ( "$dir-post/$_[1]", $_[0] ~ '/' ~ $_[1])
    }
    for @links {
        $template ~= "$ln-st href=\"$_\" $ln-end";
    }
    $template ~= "\n" ~ '~ "\n" },)';
    "templates.raku".IO.spurt: $template;
    @move-dest
}