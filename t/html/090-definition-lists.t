use v6.d;
use Test;

plan 1;

use Pod::To::HTML;
my $processor = Pod::To::HTML.processor;
my $rv;
my $pn = 0;

=begin pod

=defn  MAD
Affected with a high degree of intellectual independence.

=defn  MEEKNESS
Uncommon patience in planning a revenge that is worth while.

=defn MORAL
Conforming to a local and mutable standard of right.
Having the quality of general expediency.

=end pod

$rv = $processor.render-block( $=pod[$pn++] );

like $rv,
    /
    '<dl>'
    \s*     '<dt>MAD</dt>'
    \s*     '<dd><p>Affected with a high degree of intellectual independence.</p>'
    \s*     '</dd>'
    \s* '</dl>'
    \s* '<dl>'
    \s*     '<dt>MEEKNESS</dt>'
    \s*     '<dd><p>Uncommon patience in planning a revenge that is worth while.</p>'
    \s*     '</dd>'
    \s* '</dl>'
    \s* '<dl>'
    \s*     '<dt>MORAL</dt>'
    \s*     '<dd><p>Conforming to a local and mutable standard of right. Having the quality of general expediency.</p>'
    \s*     '</dd>'
    \s* '</dl>'
    /  , 'generated html for =defn';