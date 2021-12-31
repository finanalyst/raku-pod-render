use Test;

=begin pod

=for head1 :attr('key') :battr<key2>
This is a working header

=for head1
= attr('key) :battr<key2>
This is what is being tested

=defn Bad boy
When you B<try> to include formating.

Outside a definition list B<formating> is treated differently.

=end pod
plan 5;
is $=pod[0].contents[0].config<attr>, 'key', "'attr' is found in first header config";
todo 1;
is $=pod[0].contents[1].config<attr>, 'key', "'attr' is found in second header config";
isa-ok $=pod[0].contents[2], Pod::Defn, 'third item is a definition list';
isa-ok $=pod[0].contents[3].contents[1], Pod::FormattingCode, 'Ordinary paragraph contents has a Formatting Code';
todo 1;
isa-ok $=pod[0].contents[2].contents[1], Pod::FormattingCode, 'Definition contents has a Formatting Code';

done-testing;
