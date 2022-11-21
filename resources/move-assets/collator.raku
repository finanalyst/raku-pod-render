#!/usr/bin/env raku
use v6.d;
sub ($pp --> Positional ) {
    my @move;
    for $pp.plugin-datakeys -> $plug {
        next if $plug eq 'move-assets' ;
        my $data = $pp.get-data($plug);
        next unless $data ~~ Associative;
        with $data<assets> {
            my @todo = ("$plug/" <<~>> .list)>>.IO;
            for @todo {
                when :e & :f {
                    @move.push: ( .relative($plug), .Str )
                }
                when :e & :d {
                    @todo.append: .dir
                }
            }
        }
    }
    @move
}