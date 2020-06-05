# Be very careful with this file that the editor you use does not convert Non-breaking spaces to ordinary ones!use v6.*;

use Test;

use Pod::To::HTML;
my $processor = Pod::To::HTML.processor;
my $rv;
my $pn = 0;
plan 3;


=begin Foo
=end Foo

$rv = $processor.render-block( $=pod[$pn++] );

like $rv,
    /
    '<section name="Foo">'
    \s* '<h' .+ '<a' .+ 'Foo'
    .+ '</section>'
    /, 'section test';

=begin Foo
some text
=end Foo

$rv = $processor.render-block( $=pod[$pn++] );

like $rv,
    /
    '<section name="Foo">'
    \s* '<h' .+ '<a' .+ 'Foo'
    '</a></h'
    .+ 'some text'
    .+ '</section>'
    /, 'section + heading';

# The 'Perl 6' in the lines below should contain Non-breaking spaces, which might bot be shown as such

=head1 Talking about Perl 6

$rv = $processor.render-block( $=pod[$pn++] );

like $rv,
    / 'Perl 6' /, "no-break space is not converted to other space";