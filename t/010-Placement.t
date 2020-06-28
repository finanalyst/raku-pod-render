use Test;
use ProcessedPod;

plan 5;

my ProcessedPod $pro;
my $pv = 0;

my @templates = <raw comment escaped glossary footnotes
            format-c block-code format-u para format-b named source-wrap defn output format-l
            format-x heading title format-n format-i format-k format-p meta list subtitle format-r
            format-t table item notimplemented section toc>;

my %templates  = @templates Z=> ( "<$_> \{\{\{ contents }}} </$_>" for @templates );

$pro .= new(:%templates, :name<Testing> );

=begin pod

    =DISCLAIMER
    P<file:t/disclaimer.txt>

=end pod

my $rv = $pro.render-block( $=pod[$pv++] );
like $rv,
        /
        'ABSOLUTELY NO WARRANTY IS IMPLIED'
        /
        , 'got file';

=begin pod

    =LICENSE
    P<https://github.com/Raku/doc/blob/master/LICENSE>

=end pod

$rv = $pro.render-block( $=pod[$pv++] );
like $rv, /
        'The Artistic License 2.0'
        .+ 'Copyright (c) 2000-2006, The Perl Foundation.'
        /, 'Got a file from http';

# deliberate errors

=begin pod

    =LICENSE
    P<https://noplace__nowhere.como.uk/Raku/doc/blob/master/LICENSE>

=end pod

$rv = $pro.render-block( $=pod[$pv++] );
like $rv, /
    'See: https://noplace__nowhere.como.uk'
    /, 'Error with bad http';

=begin pod

    =DISCLAIMER
    P<file:t/disclaimer_not.txt>

=end pod

$rv = $pro.render-block( $=pod[$pv++] );
like $rv, /
    'See: file:t/disclaimer_not.txt'
    /, 'Error with bad file';

=begin pod

    =DISCLAIMER
    P<ftp://t/disclaimer.txt>

=end pod

$rv = $pro.render-block( $=pod[$pv++] );
like $rv, /
    'See: ftp://t/disclaimer.txt'
    /, 'Error with bad schema';

# Should test here with Test::Output and check the error messages with debug on.

done-testing;
