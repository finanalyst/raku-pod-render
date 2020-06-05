use v6.*;
use Test;

use Pod::To::HTML;

my $processor = Pod::To::HTML.processor;
my $rv;
my $pn = 0;

plan 4;

=begin pod

This text has no footnotes or indexed item.

=end pod
$processor.process-pod( $=pod[$pn++] );

is $processor.render-footnotes, '', 'No footnotes are rendered';

=begin pod

Some thing to say N<A footnote> in between words.

This isn't a comment and I want to add a footnoteN<next to a word>.

=end pod

$rv = $processor.render-block( $=pod[$pn++] );

like $rv, /
    '<section' .+
    \s* '<p>'
    \s* 'Some thing to say'
    \s+ '<sup><a name="fnret' .+ '" href="#fn' .+ '">[' \d+ ']</a></sup>'
    \s+ 'in between'
    .+ 'footnote<sup>'
    /, 'footnote references in text with and without spaces';

$rv = $processor.render-footnotes.subst(/\s+/,' ',:g).trim;

like $rv, /
    '<div class="footnotes">'
    \s* '<ol>'
    \s* '<li id="fn' .+ '">A footnote<a class="footnote" href="#fnret' .+ '"> « Back »</a></li>'
    \s* '<li' .+ '>next to a word<a'
    .+
    '</ol>'
    \s* '</div>'
    /, 'footnotes rendered later';

$processor.no-footnotes = True;
$rv = $processor.render-footnotes.subst(/\s+/,' ',:g).trim;

unlike $rv, / '<div class="footnotes">' / , 'footnote rendering switched off';

done-testing;