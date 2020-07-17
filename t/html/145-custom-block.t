use v6.*;
use Test;

use Pod::To::HTML;
my $rv;
my Pod::To::HTML $processor .= new;
my $pc = 0;

plan 2;

=begin pod

=for Image

Some POD

=end pod

$rv = $processor.render-block($=pod[$pc++]);

like $rv, /
    '<img src="path/to/image" width="100px" height="auto" alt="XXXXX">'
    /, 'image with dummy entries';

=begin pod

=for Image :alt<Alt expression> :width<120px> :height<100px> :src<asset/image.png>

Some POD

=end pod

$rv = $processor.render-block($=pod[$pc]);

like $rv, /
'<img src="asset/image.png" width="120px" height="100px" alt="Alt expression">'
/, 'image as required';

done-testing;
