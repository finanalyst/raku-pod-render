use v6.*;
use Test;

use ProcessedPod;
my $rv;
my $processor = ProcessedPod.new;
my $pc = 0;

plan 2;

my @templates = <block-code comment declarator defn dlist-end dlist-start escaped footnotes format-b format-c
        format-i format-k format-l format-n format-p format-r format-t format-u format-x glossary heading
        item list meta named output para pod raw source-wrap table toc >;

my %templates  = @templates Z=> @templates.map( { gen-closure-template( $_ ) });
# this creates a set of pseudo templates
$processor.templates( %templates );

=begin pod
    Some pod
=end pod

my $fn = 'xt/999-test-output';
$fn.IO.unlink if $fn.IO ~~ :e;
"$fn\.html".IO.unlink if "$fn\.html".IO ~~ :e;

$processor.file-wrap(:filename($fn));
ok $fn.IO ~~ :f, 'file is created with zero default extension';
$processor.file-wrap(:filename($fn), :ext<html>);
ok "$fn\.html".IO ~~ :f, 'file is created with given extension';

$fn.IO.unlink if $fn.IO ~~ :e;
"$fn\.html".IO.unlink if "$fn\.html".IO ~~ :e;

done-testing;
