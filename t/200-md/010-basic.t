#!/usr/bin/env perl6
use v6.*;
use Test;

use Pod::To::MarkDown;
my $rv;
my $processor;
my $pc = 0;

plan 7;

=begin pod

=TITLE Insignificant Pod

Some pod

=end pod

lives-ok { $rv = Pod::To::MarkDown.render($=pod[$pc]) }, 'captures Pod into MarkDown';

like $rv, / 'Insignificant Pod' .*? 'Some pod' .*? 'Rendered from' /, 'got consistent MarkDown';

lives-ok { $processor = Pod::To::MarkDown.new }, 'returns new object';
like $processor.^name, /'Pod::To::MarkDown'/, 'correct return type';

$processor.process-pod($=pod[$pc++]);
$rv = $processor.source-wrap;
like $rv,
        / 'Insignificant Pod' .*? 'Some pod' .*? 'Rendered from' /, 'works like render';

my $fn = 't/000-test-output';
$processor.file-wrap(:filename($fn), :ext<md>);

ok "$fn\.md".IO ~~ :f, 'file with md made';
"$fn\.md".IO.unlink if "$fn\.md".IO ~~ :e;

=begin pod
Another fascinating mess
=end pod

$rv = $processor.render-block($=pod[$pc]);

like $rv,
        / 'Another fascinating mess' /, 'latest snippit only';

done-testing;
