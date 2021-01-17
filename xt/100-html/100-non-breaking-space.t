# Be very careful with this file that the editor you use does not convert Non-breaking spaces to ordinary ones!use v6.*;

use Test;

use Pod::To::HTML2;
my $processor = Pod::To::HTML2.new;
my $rv;
my $pn = 0;
plan 1;

# The 'Perl 6' in the lines below should contain Non-breaking spaces, which might bot be shown as such

=head1 Talking about Perl 6

$rv = $processor.render-block( $=pod[$pn++] );

like $rv,
    / 'Perl 6' /, "no-break space is not converted to other space";