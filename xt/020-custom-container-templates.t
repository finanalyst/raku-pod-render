use v6.*;
use Test;

use ProcessedPod;

plan 4;

# use the Mustache variant
my ProcessedPod $pro;
my $pn = 0;

my @templates = <block-code comment declarator defn dlist-end dlist-start escaped footnotes format-b format-c
        format-i format-k format-l format-n format-p format-r format-t format-u format-x glossary heading
        item list meta named output para pod raw source-wrap table toc >;

my %templates = @templates Z=> ("\<$_>\{\{\{ contents }}}\</$_>" for @templates);
%templates<format-b> = '<new-form-b>{{ contents }}</new-form-b>';
$pro .= new(:name<Testing>);
$pro.templates(%templates);

$pro.custom = <diagram object>;
$pro.modify-templates(%( diagram => '<figure src="{{ src }}" class="{{ class }}">{{{ contents }}}</figure>',
                         object => '<object>{{{ contents }}}</object>'));
=begin pod
=for diagram :src<http://file.com/file.png> :class<one two three>
This is a caption

=for object :src<http://file.com/file.png> :class<one two three>
Some stuff

=end pod

my $rv = $pro.render-block($=pod[$pn++]);
like $rv, /
    'figure src="' \s* 'http://file.com/file.png'
    \s* '" class="' \s* ['one' \s* | 'two' \s* | 'three' \s*] ** 3  \s* '">'
    .+  'This is a caption'
    .+ '</figure>'
    .*
    '<object>' .+ 'Some stuff' .+ '</object>'
/, 'output from pod rendered by templates';

=begin pod

=for superdooper :key<pair>
Shouldn't be here

=end pod

lives-ok { $rv = $pro.render-block($=pod[$pn]) }, 'since not customised, just renders as a named block';

$pro.custom.push: 'superdooper';

throws-like { $pro.render-block($=pod[$pn++]) }, X::ProcessedPod::Non-Existent-Template,
        'traps custom object without template',
        message => / 'non-existent template ｢superdooper｣' .+ 'key' .+ 'pair' /;

=begin pod

This contains a customised F<fa-address-card> format code.

=end pod

$pro.modify-templates( %( :format-f('<i class="fa {{{ contents }}}"></i>')) );

$rv = $pro.render-block($=pod[$pn++]);
like $rv, /
    'This contains a customised </escaped><i class="fa <escaped>fa-address-card</escaped>"></i><escaped> format code.'
/, 'customised format code';

done-testing;
