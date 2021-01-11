use v6.*;
use Test;
use File::Directory::Tree;

use ProcessedPod;
my $rv;
my $processor = ProcessedPod.new;
my $pc = 0;

plan 2;

my @templates = <block-code comment declarator defn dlist-end dlist-start escaped footnotes format-b format-c
        format-i format-k format-l format-n format-p format-r format-t format-u format-x glossary heading
        item list meta named output para pod raw source-wrap table toc >;

my %templates  = @templates Z=> @templates.map( { gen-closure-template( $_ ) });
# this creates a set of pseudo templates
$processor.templates( %templates );
$processor.modify-templates( { escaped => sub ( $str ) { "<escp>$str\</escp>" } } );
=begin pod
Some pod

=for plugin
Here is some custom text
and %%interpolation%% is changed by the custom template

=end pod

my $dir = 'plugin';
rmtree($dir) if $dir.IO.e;
mktree $dir;
"$dir/templates.raku".IO.spurt( q:to/END/ );
    %( plugin => sub ( %a, %b ) {
        '<div class="myplugin">'
        ~ %a<contents>.subst(/ '%%' ~ '%%' .+ /, %a<plugin-data> )
        ~ </div>
        },
    )
    END
"$dir/blocks.raku".IO.spurt( q:to/END/ );
    < plugin >
    END
"$dir/data.raku".IO.spurt( q:to/END/ );
    'NEW WORDS'
    END

$processor.add-plugin('plugin');
$rv = $processor.render-block( $=pod[$pc++] );

like $rv, /
    '<div class="myplugin">'
    .* 'Here is some custom text'
    \s+ 'and'
    \s+ 'NEW WORDS'
    \s+ 'is changed by the custom template'
    /, 'plugin works with default name-space';

=begin pod
Some pod

=for testing :template<myplugin> :name-space<newspace>
Here is some custom text
and %%interpolation%% is changed by the custom template

=end pod

"$dir/templates.raku".IO.spurt( q:to/END/ );
    %( myplugin => sub ( %a, %b ) {
        '<div class="myplugin">'
        ~ %a<contents>.subst(/ '%%' ~ '%%' .+ /, %a<newspace-data> )
        ~ </div>
        },
    )
    END
"$dir/blocks.raku".IO.spurt( q:to/END/ );
    < testing >
    END
"$dir/data.raku".IO.spurt( q:to/END/ );
    'VERY NEWX WORDS'
    END

$processor.add-plugin('plugin', :name-space<newspace> );
$rv = $processor.render-block( $=pod[$pc++] );

like $rv, /
'<div class="myplugin">'
.* 'Here is some custom text'
\s+ 'and'
\s+ 'VERY NEWX WORDS'
\s+ 'is changed by the custom template'
/, 'plugin works with different name-space';

rmtree($dir) if $dir.IO.e;

done-testing;
