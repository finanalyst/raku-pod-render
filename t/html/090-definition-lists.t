use v6.d;
use Test;

plan 1;

use Pod::To::HTML;
my $processor = Pod::To::HTML.new;
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
    \s*     '<dd>Affected with a high degree of intellectual independence.'
    \s*     '</dd>'
    \s*     '<dt>MEEKNESS</dt>'
    \s*     '<dd>Uncommon patience in planning a revenge that is worth while.'
    \s*     '</dd>'
    \s*     '<dt>MORAL</dt>'
    \s*     '<dd>Conforming to a local and mutable standard of right. Having the quality of general expediency.'
    \s*     '</dd>'
    \s* '</dl>'
    /  , 'generated html for =defn';
