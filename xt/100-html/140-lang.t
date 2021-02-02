use v6;
use Test;
use Pod::To::HTML2;
my $processor = Pod::To::HTML2.new;
my $rv;
my $pn = 0;

plan 2;

=begin pod

Je suis Napoleon!

=end pod
$processor.no-meta = $processor.no-footnotes = $processor.no-glossary = $processor.no-toc = True;
$processor.process-pod( $=pod[$pn++] );

like $processor.source-wrap, /'<html lang="en">'/, 'default lang is English';
$processor.pod-file.lang = 'fr';
like $processor.source-wrap, /'<html lang="fr">'/, 'custom lang';
