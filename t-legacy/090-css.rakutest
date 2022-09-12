use v6;
use Test;
use Pod::To::HTML2;

plan 2;

=begin pod

Je suis Napoleon!

=end pod

like pod2html($=pod), /'<link rel="stylesheet" href='/, 'default includes CSS';
unlike pod2html($=pod, :lang<fr>, :css-url('')),
    /'<link rel="stylesheet" href='/,
    'empty string for CSS URL disables CSS inclusion';
