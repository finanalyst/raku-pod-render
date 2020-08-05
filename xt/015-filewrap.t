use v6.*;
use Test;

use ProcessedPod;
my $rv;
my $processor = ProcessedPod.new;
my $pc = 0;

plan 2;

my @templates = <raw comment escaped glossary footnotes head header footer declarator dlist-start dlist-end
            format-c block-code format-u para format-b named source-wrap defn output format-l
            format-x heading title format-n format-i format-k format-p meta list subtitle format-r
            format-t table item notimplemented section toc pod >;

my %templates = @templates Z=> ( "[beg]$_\[end]" for @templates );
# this creates a set of pseudo templates
$processor.templates( %templates );

=begin pod
    Some pod
=end pod

my $fn = 't/999-test-output';
$fn.IO.unlink if $fn.IO ~~ :e;
"$fn\.html".IO.unlink if "$fn\.html".IO ~~ :e;

$processor.file-wrap(:filename($fn));
ok $fn.IO ~~ :f, 'file is created with zero default extension';
$processor.file-wrap(:filename($fn), :ext<html>);
ok "$fn\.html".IO ~~ :f, 'file is created with given extension';

$fn.IO.unlink if $fn.IO ~~ :e;
"$fn\.html".IO.unlink if "$fn\.html".IO ~~ :e;

done-testing;
