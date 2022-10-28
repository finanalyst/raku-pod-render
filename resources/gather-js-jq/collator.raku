sub ( $pp --> Positional ) {
    my Bool $loadjq-lib = False;
    my @js;
    my @js-bottom;
    my %own-config = EVALFILE 'config.raku';
    for $pp.plugin-datakeys -> $plug {
        next if $plug eq 'js-collator' ;
        my $data = $pp.get-data($plug);
        next unless $data ~~ Associative;
        for $data.keys {
            when $_ ~~ 'js-script' and $data{$_} ~~ Str:D {
                @js.push( ($data{$_}, $plug, 0 ) )
            }
            when $_ ~~ 'js-link' and $data{$_} ~~ Str:D {
                @js.push( ($data{$_}, '', 0 ) )
            }
            when $_ ~~ 'js-bottom' and $data{$_} ~~ Str:D {
                @js-bottom.push(( $data{$_}, $plug, 0 ));
            }
            when $_ ~~ 'jquery' and $data{$_} ~~ Str:D {
                @js.push(( $data{$_}, $plug, 0 ));
                $loadjq-lib = True
            }
            when $_ ~~ 'jquery-link' and $data{$_} ~~ Str:D {
                @js.push( ($data{$_}, '', 0 ) );
                $loadjq-lib = True
            }
            # handle higher order parameters.
            when $_ ~~ 'js-script' and $data{$_} ~~ Positional {
                ( note "[{$?FILE.IO.basename}] ignoring invalid 'js-script' config data from ｢$plug｣, viz. ｢{ $data{$_}[0] }｣ or ｢{ $data{$_}[1] }｣" ) and next
                    unless ($data{$_}[0] ~~ Str:D and +$data{$_}[1] ~~ Int:D);
                @js.push( ($data{$_}[0], $plug, +$data{$_}[1] ) )
            }
            when $_ ~~ 'js-link' and $data{$_} ~~ Positional {
                ( note "[{$?FILE.IO.basename}] ignoring invalid 'js-link' config data from ｢$plug｣, viz. ｢{ $data{$_}[0] }｣ or ｢{ $data{$_}[1] }｣" ) and next
                unless ($data{$_}[0] ~~ Str:D and +$data{$_}[1] ~~ Int:D);
                @js.push( ($data{$_}[0], '', +$data{$_}[1] ) )
            }
            when $_ ~~ 'js-bottom' and $data{$_} ~~ Positional {
                ( note "[{$?FILE.IO.basename}] ignoring invalid 'js-bottom' config data from ｢$plug｣, viz. ｢{ $data{$_}[0] }｣ or ｢{ $data{$_}[1] }｣" ) and next
                unless ($data{$_}[0] ~~ Str:D and +$data{$_}[1] ~~ Int:D);
                @js-bottom.push(( $data{$_}[0], $plug, +$data{$_}[1] ));
            }
            when $_ ~~ 'jquery' and $data{$_} ~~ Positional {
                ( note "[{$?FILE.IO.basename}] ignoring invalid 'jquery' config data from ｢$plug｣, viz. ｢{ $data{$_}[0] }｣ or ｢{ $data{$_}[1] }｣" ) and next
                unless ($data{$_}[0] ~~ Str:D and +$data{$_}[1] ~~ Int:D);
                @js.push(( $data{$_}[0], $plug, +$data{$_}[1] ));
                $loadjq-lib = True
            }
            when $_ ~~ 'jquery-link' and $data{$_} ~~ Positional {
                ( note "[{$?FILE.IO.basename}] ignoring invalid 'jquery-link' config data from ｢$plug｣, viz. ｢{ $data{$_}[0] }｣ or ｢{ $data{$_}[1] }｣" ) and next
                unless ($data{$_}[0] ~~ Str:D and +$data{$_}[1] ~~ Int:D);
                @js.push( ($data{$_}[0], '', +$data{$_}[1] ) );
                $loadjq-lib = True
            }
        }
    }
    my $template = "\%( \n "; # empty list emitted if not jq/js
    $template ~= 'jq-lib => sub (%prm, %tml) {'
        ~ "\n\'\<script src=\"" ~ %own-config<jquery-lib> ~ '"></script>' ~ "\' \n},\n"
        if $loadjq-lib;
    my @move-dest;
    my $elem;
    for @js.sort({.[2]}) -> ($file, $plug, $order ){
        FIRST {
            $template ~= 'js => sub (%prm, %tml) {' ;
            $elem = 0;
        }
        LAST {
            $template ~= "},\n"
        }
        $template ~= ( $elem ?? '~ ' !! '' )
                ~ '\'<script '
                ~ ( $plug ?? 'src="/assets/scripts/' !! '' )
                ~ $file
                ~ ( $plug ?? '"' !! '' )
                ~ ">\</script>'\n";
        ++$elem;
        @move-dest.append( $file ) if $plug
    }
    for @js-bottom.sort({.[2]}) -> ($file, $plug ){
        FIRST {
            $template ~= 'js-bottom => sub (%prm, %tml) {' ;
            $elem = 0;
        }
        LAST {
            $template ~= "},\n"
        }
        $template ~= ( $elem ?? '~ ' !! '' ) ~ '\'<script src="/assets/scripts/' ~ $file ~ "\"\>\</script>'\n";
        ++$elem;
        @move-dest.append( $file )
    }
    $template ~= ")\n";
    "templates.raku".IO.spurt($template);
    @move-dest
}