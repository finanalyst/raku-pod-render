use v6.*;
use Test;

use Pod::To::HTML2;
my $processor = Pod::To::HTML2.new;
my $rv;
my $pn = 0;

plan 3;

=begin pod

There is no meta data here

=end pod

$processor.process-pod( $=pod[$pn++] );
is $processor.render-meta, '', 'No meta data is rendered';

=begin pod

This text has no footnotes or indexed item.
=AUTHOR An author is named

=SUMMARY This page is about Perl 6
=end pod

$processor.process-pod( $=pod[$pn++] );
$rv = $processor.render-meta.subst(/\s+/,' ',:g).trim;
like $rv, /
    \s* '<meta name="author" value="An author' .+ '"' .+ '/>'
    .+ '<meta name="summary" value="This page' .+ '/>'
    /, 'meta is rendered';

$processor.no-meta = True;

unlike $processor.render-meta, / '<meta name="author' /, "Meta flag cancels rendering of meta data";

