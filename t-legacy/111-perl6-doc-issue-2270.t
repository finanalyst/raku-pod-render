use Test;
use Pod::To::HTML2;
plan 1;

my $question-mark = Pod::FormattingCode.new(
        type     => 'L',
        contents => ["?"],
        meta     => ["%3F"],
    );

ok pod2html($question-mark) ~~ /\%3F/;


