use v6.*;
use Test;

use Pod::To::HTML;
my $processor = Pod::To::HTML.processor;
my $rv;
my $pn = 0;

plan 2;

=begin pod

    =DISCLAIMER
    P<file:t/disclaimer.txt>

=end pod

$rv = $processor.render-block( $=pod[$pn++] );
like $rv,
        /
        'ABSOLUTELY NO WARRANTY IS IMPLIED'
        /
        , 'got file';

=begin pod

    =EVIL
    P<file:t/badfile.txt>

=end pod

$rv = $processor.render-block( $=pod[$pn++] );
like $rv, /
'The text contains a &lt;/pre&gt; which could cause formatting problems'
/, 'Escape out containers';

done-testing;
