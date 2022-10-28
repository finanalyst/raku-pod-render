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
            @adds.push( ($_ , $data<add-css>) )
        }
    }
    return () unless $css or +@adds or +@links;
    my $template = q:to/TEMP/;
        %( css => sub (%prm, %tml) {
        "\n" ~ '<link rel="stylesheet" href="rakudoc-styling.css">'
        TEMP
    my @move-dest;
    if $css {
        # remove any .ccs.map references in text as these are not loaded
        $css.subst-mutate(/ \n \N+ '.css.map' .+? $$/, '', :g);
        my $fn = 'rakudoc-extra.css';
        $fn.IO.spurt($css);
        $template ~= "\n" ~ '~ "\n" ~ ' ~ "'<link rel=\"stylesheet\" href=\"$fn\">'";
        @move-dest.append: $fn
    }
    else { $template ~= ' "" ' } # Template is describing a subroutine that emits a string, which must be started by css
    for @adds {
        $template ~= "\n" ~ '~ "\n" ~ ' ~ "'<link rel=\"stylesheet\" href=\"/assets/css/{ $_[1] }\"/>'";
        @move-dest.append: $_[1]
    }
    for @links {
        $template ~= "\n" ~ '~ "\n" ~ ' ~ "'<link rel=\"stylesheet\" $_ />'";
    }
    $template ~= "\n" ~ '~ "\n" },)';
    "templates.raku".IO.spurt: $template;
    @move-dest
}