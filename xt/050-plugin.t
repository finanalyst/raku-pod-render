use v6.*;
use Test;
use File::Directory::Tree;

use ProcessedPod;
my $rv;
my $processor = ProcessedPod.new;
my $pc = 0;

plan 8;

my @templates = <block-code comment declarator defn dlist-end dlist-start escaped footnotes format-b format-c
        format-i format-k format-l format-n format-p format-r format-t format-u format-x glossary heading
        item list meta named output para pod raw source-wrap table toc >;

my %templates  = @templates Z=> @templates.map( { gen-closure-template( $_ ) });
# this creates a set of pseudo templates
$processor.templates( %templates );
$processor.modify-templates( { escaped => sub ( $str ) { "<escp>$str\</escp>" } } );

=begin pod

=newblocktype Here are some words

=end pod

$rv = $processor.render-block($=pod[$pc]);
unlike $rv, /
    '<newblocktype>'
    .+ '</newblocktype>'
    /, 'new block treated as ordinary named';

$processor.add-custom(['newblocktype',]);
$processor.modify-templates( %( 'newblocktype' => gen-closure-template( 'newblocktype' )) );
$rv = $processor.render-block($=pod[$pc++]);
like $rv, /
    '<newblocktype>'
    .+ '</newblocktype>'
    /, 'new block gets template';

$rv = $processor.pod-file.raw-toc.raku;
like $rv, /
    'Here are some words'
    /, 'Block\'s content has been added to TOC';

=begin pod

=for newblocktype :headlevel<0>
This one is different

=end pod
$processor.render-block($=pod[$pc++]);
$rv = $processor.pod-file.raw-toc.raku;
unlike $rv, /
    'This one is different'
    /, 'Block\'s content has not been added to TOC';

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
        ~ %a<contents>.subst(/ '%%' ~ '%%' .+ /, %a<plugin><data> )
        ~ </div>
        },
        myplugin => sub ( %a, %b ) {
        '<div class="myplugin">'
        ~ %a<contents>.subst(/ '%%' ~ '%%' .+ /, %a<newspace><stuff> )
        ~ </div>
        },
    )
    END
"$dir/blocks.raku".IO.spurt( q:to/END/ );
    < plugin testing >
    END

$processor.add-plugin('plugin', :config(%(
    :data('NEW WORDS')
)));
$rv = $processor.render-block( $=pod[$pc++] );

throws-like { $processor.add-plugin('plugin',:path($dir) ) },
        X::ProcessedPod::NamespaceConflict,
        message => / 'overwrite plugin' /,
        'tried to add plugin again';

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

$processor.add-data( 'newspace', %( :stuff('VERY NEWX WORDS'),  )  );

$rv = $processor.render-block( $=pod[$pc++] );

like $rv, /
'<div class="myplugin">'
.* 'Here is some custom text'
\s+ 'and'
\s+ 'VERY NEWX WORDS'
\s+ 'is changed by the custom template'
/, 'plugin works with different name-space';

rmtree($dir);

# now in another directory
$dir = 'xt/xplugin';
rmtree($dir) if $dir.IO.e;
mktree($dir);

=begin pod
Some pod

=for testing :template<myplugin>
Here is some custom text
with no data

=end pod

"$dir/templates.raku".IO.spurt( q:to/END/ );
    %( myplugin => sub ( %a, %b ) {
        '<div class="myplugin">'
        ~ %a<contents>
        ~ </div>
        },
    )
    END
"$dir/blocks.raku".IO.spurt( q:to/END/ );
    < testing >
    END

$processor.add-plugin('xplugin',:path($dir) );
$rv = $processor.render-block( $=pod[$pc++] );

like $rv, /
'<div class="myplugin">'
.* 'Here is some custom text'
\s+ 'with no data'
/, 'plugin works with blank data in another directory';

rmtree($dir);
done-testing;
