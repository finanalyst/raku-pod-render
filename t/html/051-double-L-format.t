use Test;
use Pod::To::HTML;
my $pro = Pod::To::HTML.new;
my $rv;
my $pn = 0;

plan 1;

=begin pod

Otherwise it constructs a L<Block|/type/Block>.
To force construction of a L<Block|/type/Block>, follow the opening brace with a semicolon.

=end pod

$rv = $pro.render-block( $=pod[$pn++] );
like $rv, /
        'Otherwise it constructs a <a href="/type/Block.html">Block</a>.'
        \s*'To force construction of a <a href="/type/Block.html">Block</a>'
        ', follow the opening brace with a semicolon.'
    /, 'double link points to same place';

done-testing;