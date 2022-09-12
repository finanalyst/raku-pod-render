use Test;
use Pod::To::MarkDown;
my $rv;
my $processor = Pod::To::MarkDown.new;
my $pc = 0;
plan 3;

=begin pod

We can L<Link to a place|https://docs.raku.org> with no problem.

This L<link should fail|https://xxxxxioioioi.com> with a bad response code.

We also can L<link to an index test code|format-code-index-test-pod-file_2#an item> with more text.

Linking inside the file is L<like this|#Here is a header>.

Hold over from Perl5 L<module ref|path::to::file>.

And with internal L<module int|path::to::file#this::keeps>.

Also L<keep double colon|local/file#double::colon::ok>.

Some stuff

=head1 Here is a header

=end pod

$rv = $processor.render-block( $=pod[$pc++] );

like $rv, /
    \s* 'We can'
    \s* '[Link to a place](https://docs.raku.org)'
    \s* 'with no problem.'
    /, 'plain external link';
todo 1;
like $rv, /
    'We also can'
    \s* '[link to an index test code](format-code-index-test-pod-file_2.md#an item)'
        /, 'local link';
todo 1;
like $rv, /
    'inside the file is'
    \s* '[like this](Here_is_a_header)'
    /, 'internal link';

done-testing;
