use Test;
use Pod::To::HTML;
my $rv;
my Pod::To::HTML $processor .= new;
my $pc = 0;

#plan 4;
plan 2;

##| This is a variable
#my $variable;
#
#todo 'to be implemented ';
#$rv = $processor.render-block($=pod[$pc++]);
#like $rv, /
#    '<article>'
#    '<code class=\"pod-code-inline\">my $variable</code>'
#    'This is a variable'
#    '</article>'
#    /, 'variable top comment ok';
#
#my $under-variable;
##= Some under content
#
#todo 'to be implemented';
#$rv = $processor.render-block($=pod[$pc++]);
#like $rv, /
#'thing'
#/, 'under comment ok';

#| Here is a subroutine with a signature
sub a-nice-sub(Str $fish, :$fingers = 'real potato' ) { my $y = 2; }

$rv = $processor.render-block($=pod[$pc++]);

like $rv, /
    '<article>'
    '<code class="pod-code-inline">sub a-nice-sub (Str $fish, :$fingers = "real potato") </code>'
    'Here is a subroutine with a signature'
    '</article>'
/, 'sub comment ok';

#| This is a proto
proto sub flamingo( $one, $two, $three ) {*}

$rv = $processor.render-block($=pod[$pc++]);
like $rv, /
    '<article>'
    '<code class="pod-code-inline">proto sub flamingo ($one, $two, $three) </code>'
    'This is a proto'
    '</article>'
/, 'proto comment ok';

done-testing;
