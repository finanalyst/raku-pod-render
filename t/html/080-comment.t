use v6.*;
use Test;

use Pod::To::HTML;
my $processor = Pod::To::HTML.processor;
my $rv;
my $pn = 0;

plan 1;

=begin pod
=for comment
foo foo not rendered
bla bla    bla

This isn't a comment
=end pod

$processor.process-pod( $=pod[$pn++] );
$rv = $processor.body-only;

like $rv,
    /
    '<section name="___top">'
    \s* '<p>This isn\'t a comment</p>'
    \s* '</section>'
    /, 'commment is eliminated';