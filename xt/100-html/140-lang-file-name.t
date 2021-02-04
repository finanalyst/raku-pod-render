use v6;
use Test;
use Pod::To::HTML2;
my $processor = Pod::To::HTML2.new(:min-top);
my $rv;
my $pn = 0;

plan 3;

=begin pod

Je suis Napoleon!

=end pod
$processor.no-meta = $processor.no-footnotes = $processor.no-glossary = $processor.no-toc = True;
$processor.process-pod( $=pod[$pn++] );

like $processor.source-wrap, /'<html lang="en">'/, 'default lang is English';
$processor.pod-file.lang = 'fr';
like $processor.source-wrap, /'<html lang="fr">'/, 'custom lang';

$processor.pod-file.name = 'name-test';

$rv = $processor.source-wrap;
like $rv,
         /
         'Rendered from'
         .+ 'name-test'
         /, 'file name changed'