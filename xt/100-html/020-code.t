use v6.*;
use Test;

use Pod::To::HTML;
my $processor = Pod::To::HTML.new;
my $rv;
my $pn = 0;

plan 3;

=begin pod
This ordinary paragraph introduces a code block:

    $this = 1 * code('block');
    $which.is_specified(:by<indenting>);
=end pod

$rv = $processor.render-block( $=pod[$pn++] );

like $rv,
    /
    '<p>' \s* 'This ordinary paragraph introduces a code block:' \s* '</p>'
     \s* '<pre class="pod-block-code">' \s* '$this = 1 * code(\'block\');'
     \s* '$which.is_specified(:by&lt;indenting&gt;);</pre>'
     /, 'code block';


=begin pod
This is an ordinary paragraph

    While this is not
    This is a code block

    =head1 Mumble: "mumble"

    Surprisingly, this is not a code block
        (with fancy indentation too)

But this is just a text. Again

=end pod

$rv = $processor.render-block( $=pod[$pn++] );
like $rv,
    /
    '<p>' \s* 'This is an ordinary paragraph' \s* '</p>'
    \s* '<pre class="pod-block-code">'
    \s* 'While this is not'
    \s* 'This is a code block</pre>'
    \s* '<h1 id="Mumble:_&quot;mumble&quot;">'
    \s* '<a' \s* [ 'class="u"' \s* | 'href="#___top"' \s* | 'title="go to top of document"' \s* ]**3 '>'
    \s* 'Mumble: &quot;mumble&quot;'
    \s* '</a>'
    \s* '</h1>'
    \s* '<p>' \s* 'Surprisingly, this is not a code block (with fancy indentation too)' \s* '</p>'
    \s* '<p>' \s* 'But this is just a text. Again' \s* '</p>'
    /, 'mixed paragraphs and code';

$processor.highlighter = sub ( $content --> Str ) {
    "<highlighter>$content\</highlighter>"
}

$rv = $processor.render-block( $=pod[0] ); # call initial code and highlight it

like $rv,
        /
        \s* '<pre class="pod-block-code">'
        \s* '<highlighter>'
        \s* '$this = 1 * code(\'block\');'
        \s* '$which.is_specified(:by&lt;indenting&gt;);'
        \s* '</highlighter>'
        \s* '</pre>'
        /, 'highighter callback worked';
