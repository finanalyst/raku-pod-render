#!/usr/bin/env perl6
use v6.*;
use Test;

use Pod::To::HTML2;
my $rv;
my $processor;
my $pc = 0;

plan 12;

=begin pod

Some pod

=end pod

lives-ok { $rv = Pod::To::HTML2.render($=pod[$pc]) }, 'captures Pod into HTML';

like $rv, / .*? '<html' .*? '>' .*? '<body' .*? '>' .*? 'Some pod' .*? '</body>' .*? '</html>' /, 'got consistent HTML';

lives-ok { $processor = Pod::To::HTML2.new }, 'returns new object';
like $processor.^name, /'Pod::To::HTML2'/, 'correct return type';
$processor.process-pod($=pod[$pc++]);
$rv = $processor.source-wrap;
like $rv,
        / .*? '<html' .*? '>' .*? '<body' .*? '>' .*? 'Some pod' .*? '</body>' .*? '</html>' /, 'works like render';
like $rv, / '<head' .+? '<style>' .+? '</style>' /, 'style information is in place';

like $rv,
        / 'href="data:image/x-icon;base64,AAABAA' /, 'correct icon content start';
like $rv,
        / '<svg version="1.1" id="Camelia_bug"' /, 'correct camelia svg start';
$rv = $processor.pod-body;
like $rv,
        / '<section' .*? '>' .*? 'Some pod' .*? '</section>' /, 'html but no file wrapping';
unlike $rv,
        / .*? '<html' .*? '>' .*? '<body' .*? '>' .*? '</body>' .*? '</html>' /, 'confirm there is not html wrapping';

my $fn = 't/999-test-output';
"$fn\.html".IO.unlink if "$fn\.html".IO ~~ :e;

$processor.file-wrap(:filename($fn));
ok "$fn\.html".IO ~~ :f, 'file is created with html as default extension';

"$fn\.html".IO.unlink if "$fn\.html".IO ~~ :e;

=begin pod
Another fascinating mess
=end pod

$rv = $processor.render-block($=pod[$pc]);

like $rv,
        / '<section' .*? '>' .*? 'Another fascinating mess' .*? '</section>' /, 'latest snippit only';

done-testing;
