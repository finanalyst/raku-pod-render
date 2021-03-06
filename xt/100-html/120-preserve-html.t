use v6.*;
use Test;

use Pod::To::HTML2;
my $processor = Pod::To::HTML2.new;
my $rv;
my $pn = 0;

plan 1;

=begin Html
<img style="float: right; margin: 0 0 1em 1em; width:261px" src="/images/Camelia.svg" alt="" id="home_logo"/>
Welcome to the official documentation of the <a href="https://raku.org">Raku</a>
programming language!
Besides online browsing and searching, you can also
<a href="/raku.html">view everything in one file</a> or
<a href="https://github.com/raku/doc">contribute</a>
by reporting mistakes or sending patches.

<hr/>
=end Html

$rv = $processor.render-block( $=pod[$pn++] );

like $rv, /
    '<img style="float: right; margin: 0 0 1em 1em; width:261px" src="/images/Camelia.svg" alt="" id="home_logo"/>'
    \s* ' Welcome to the official documentation of the <a href="https://raku.org">Raku</a> programming language!'
    \s* 'Besides online browsing and searching, you can also <a href="/raku.html">view everything in one file</a> or'
    \s* '<a href="https://github.com/raku/doc">contribute</a> by reporting mistakes or sending patches.<hr/>'
    /, 'html as expected';