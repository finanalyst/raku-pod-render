use v6.*;
use Test;

use ProcessedPod;

plan 3;

my ProcessedPod $pro;

my @templates = <raw comment escaped glossary footnotes head header footer dlist-start dlist-end
            format-c block-code format-u para format-b named source-wrap defn output format-l
            format-x heading title format-n format-i format-k format-p meta list subtitle format-r
            format-t table item notimplemented section toc pod >;

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

my $rv = $pro.render-block($=pod[0]);
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

lives-ok { $rv = $pro.render-block($=pod[1]) }, 'since not customised, just renders as a named block';

$pro.custom.push: 'superdooper';

throws-like { $pro.render-block($=pod[1]) }, X::ProcessedPod::Non-Existent-Template,
        'traps custom object without template',
        message => / 'non-existent template ｢superdooper｣' .+ 'key' .+ 'pair' /;

done-testing;
