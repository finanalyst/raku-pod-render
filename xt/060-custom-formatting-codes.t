use v6.*;
use Test;
use File::Directory::Tree;

use ProcessedPod;
my $rv;
my $processor = ProcessedPod.new;
my $pc = 0;

plan 4;

my @templates = <block-code comment declarator defn dlist-end dlist-start escaped footnotes format-b format-c
        format-i format-k format-l format-n format-p format-r format-t format-u format-x glossary heading
        item list meta named output para pod raw source-wrap table toc >;

my %templates  = @templates Z=> @templates.map( { gen-closure-template( $_ ) });
# this creates a set of pseudo templates
$processor.templates( %templates );
$processor.modify-templates( %(
# escape must work on each non-space character, not on the string!!! So test with .uc
    escaped => sub ( $str ) { $str.uc },
));

=begin pod
This text has a F<fa-snowflake-o> icon
=end pod

$rv = $processor.render-block($=pod[$pc++]);
like $rv,
        /
        'F<FA-SNOWFLAKE-O>'
        /, 'no special rendering of F a fa';

$processor.modify-templates( %(
    :format-f( sub (%prm, %tmpl) { "<i class=\"fa { %prm<contents> }\"></i>" }),
    format-s => sub (%prm, %tmpl) {
        '<div class="' ~ %prm<meta>[0] ~ '">' ~ %prm<contents> ~ '</div>'
    },
    format-w => sub (%prm, %tmpl) {
        "<div class=\"{ %prm<meta>[0] }\" on-click=\"{ %prm<meta>[1] }\">{ %prm<contents> }</div>"
    },
));

=begin pod
This text has a F<fa-snowflake-o> icon
=end pod

$rv = $processor.render-block($=pod[$pc++]);
like $rv,
        /
        '<i class="fa FA-SNOWFLAKE-O"></i>'
        /, 'renders a fa';

=begin pod
This is an item for sale S<Click to purchase with XXXProvider | xxxprovider_button>
=end pod

$rv = $processor.render-block($=pod[$pc++]);
like $rv,
        /
        '<div class="XXXPROVIDER_BUTTON">CLICK TO PURCHASE WITH XXXPROVIDER</div>'
        /, 'renders an s';
=begin pod
This is an item for sale W<Click to purchase with XXXProvider | xxxprovider_button; some-js-function> and stuff
=end pod

$rv = $processor.render-block($=pod[$pc++]);
like $rv,
        /
        '<div class="XXXPROVIDER_BUTTON"'
        \s+ 'on-click="SOME-JS-FUNCTION">'
        'CLICK TO PURCHASE WITH XXXPROVIDER</div>'
        /, 'renders an w';

done-testing;
