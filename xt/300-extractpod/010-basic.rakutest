use Test;
use ExtractPod;
my $rv;

plan 3;

throws-like { load('xt/300-extractpod/nonexistent') }, X::ExtractPod::NoSuchSource, 'got no file error';
lives-ok { $rv = load('xt/300-extractpod/Classic.pm6')} , 'loaded module';
is $rv[0].^name, 'Pod::Block::Named', 'first element of tree correct';

done-testing;
