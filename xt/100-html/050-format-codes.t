use v6.*;
use Test;

use Pod::To::HTML;
my $processor = Pod::To::HTML.new;
my $rv;
my $pn = 0;

plan 17;

=begin pod

Some thing to B<say> in between words.

This isn't a comment and I want to add a formatB<next to a word>in the middle.

=end pod
$rv = $processor.render-block( $=pod[$pn++] );

like $rv, /
    '<section'
    .+? '<p>'
    \s* 'Some thing to'
    \s+ '<strong>say</strong>'
    \s+ 'in between words.'
    /, 'bold when separated with a space';

like $rv, /
    'I want to add a format<strong>next to a word</strong>' \s* 'in the middle.'
    /, 'bold without spaces';


=begin pod

Some thing to I<say> in between words.

This isn't a comment and I want to add a formatI<next to a word>in the middle.

=end pod
$rv = $processor.render-block( $=pod[$pn++] );

like $rv, /
    '<section'
    .+? '<p>'
    \s* 'Some thing to'
    \s+ '<em>say</em>'
    \s+ 'in between words.'
    /, 'Important when separated with a space';

like $rv, /
    'I want to add a format<em>next to a word</em>' \s* 'in the middle.'
    /, 'Important without spaces';


=begin pod

Some thing to U<say> in between words.

This isn't a comment and I want to add a formatU<next to a word>in the middle.

=end pod
$rv = $processor.render-block( $=pod[$pn++] );

like $rv, /
    '<section'
    .+? '<p>'
    \s* 'Some thing to'
    \s+ '<u>say</u>'
    \s+ 'in between words.'
    /, 'Unusual when separated with a space';

like $rv, /
    'I want to add a format<u>next to a word</u>'
    \s* 'in the middle.'
    /, 'Unusual without spaces';


=begin pod

Some thing to B<I<say> embedded> in between words.

=end pod
$rv = $processor.render-block( $=pod[$pn++] );

like $rv, /
    '<section'
    .+? '<p>'
    \s* 'Some thing to'
    \s+ '<strong><em>say</em> embedded</strong>'
    \s+ 'in between words.'
    /, 'Embedded codes when separated with a space';


=begin pod

Some thing to C<say> in between words.
=end pod
$rv = $processor.render-block( $=pod[$pn++] );

like $rv, /
    '<section'
    .+? '<p>'
    \s* 'Some thing to'
    \s+ '<code>say</code>'
    \s+ 'in between words.'
    /, 'C format';


=begin pod

Some thing to K<say> in between words.
=end pod
$rv = $processor.render-block( $=pod[$pn++] );

like $rv, /
    '<section'
    .+? '<p>'
    \s* 'Some thing to'
    \s+ '<kbd>say</kbd>'
    \s+ 'in between words.'
    /, 'K format';


=begin pod

Some thing to R<say> in between words.
=end pod
$rv = $processor.render-block( $=pod[$pn++] );

like $rv, /
    '<section'
    .+? '<p>'
    \s* 'Some thing to'
    \s+ '<var>say</var>'
    \s+ 'in between words.'
    /, 'R format';


=begin pod

Some thing to T<say> in between words.
=end pod
$rv = $processor.render-block( $=pod[$pn++] );

like $rv, /
    '<section'
    .+? '<p>'
    \s* 'Some thing to'
    \s+ '<samp>say</samp>'
    \s+ 'in between words.'
    /, 'T format';


=begin pod
Perl 6 makes considerable use of the E<171> and E<187> characters.
Perl 6 makes considerable use of the E<laquo> and E<raquo> characters.
Perl 6 makes considerable use of the E<0b10101011> and E<0b10111011> characters.
Perl 6 makes considerable use of the E<0o253> and E<0o273> characters.
Perl 6 makes considerable use of the E<0d171> and E<0d187> characters.
Perl 6 makes considerable use of the E<0xAB> and E<0xBB> characters.
=end pod
$rv = $processor.render-block( $=pod[$pn++] );

like $rv, /
    '<section'
    .+? [ .+? 'use of the ' [ '&laquo;' | '&#171;' ]  ' and ' [ '&raquo;' | '&#187;' ] ' characters' ] **6
    /, 'Unicode E format 6 times same';


    =begin pod

    Perl 6 is awesomeZ<Of course it is!> without doubt.
    =end pod
$rv = $processor.render-block( $=pod[$pn++] );

like $rv, /
    '<section'
    .+? '<p>'
    \s* 'Perl 6 is awesome without doubt.'
    /, 'Z format';


=begin pod

We can L<Link to a place|https://docs.raku.org> with no problem.

This L<link should fail|https://xxxxxioioioi.com> with a bad response code.

We also can L<link to an index test code|format-code-index-test-pod-file_2#an item> with more text.

Linking inside the file is L<like this|#Here is a header>.

Some stuff

=head1 Here is a header

=end pod

$rv = $processor.render-block( $=pod[$pn++] );

like $rv, /
    '<section'
    .+? '<p>'
    \s* 'We can'
    \s* '<a href="https://docs.raku.org">Link to a place</a>'
    \s* 'with no problem.'
    .+ '<a href="format-code-index-test-pod-file_2#an item">link to an index test code</a>'
    .+ '<a href="#Here_is_a_header">like this</a>'
    .+ '<h1' .+ 'id="Here_is_a_header"'
    /, 'L format creates links';

# todo a test about links not mangling.

=begin pod

Some thing to V< B<say> C<in>> between words.
=end pod
$rv = $processor.render-block( $=pod[$pn++] );

like $rv, /
    '<section'
    .+? '<p>'
    \s* 'Some thing to'
    \s+ 'B&lt;say&gt;'
    \s+ 'C&lt;in&gt; between words.'
    /, 'V format';


=begin pod

Some thing ß<a-filename.pod> between words.

=end pod

$rv = $processor.render-block( $=pod[$pn++] );

like $rv, /
    '<section'
    .+? '<p>'
    \s* 'Some thing'
    \s+ 'ß&lt;a-filename.pod&gt;'
    \s+ 'between words.'
    /, 'Unknown format';

=begin pod

Some thing B<<a-filename.pod>> with multiple brackets.

Sequences of brackets I<<<here I am>>> and  T<<<<here I am>>>> that parse.

=end pod
$rv = $processor.render-block( $=pod[$pn++] );

like $rv, /
    '<section'
    .+? '<p>'
    \s* 'Some thing'
    \s+ '<strong>a-filename.pod</strong>'
    \s+ 'with multiple brackets.'
    .+ 'Sequences of brackets'
    \s+ '<em>here I am</em> and <samp>here I am</samp> that parse.'
    /, 'multiple brackets';

done-testing;