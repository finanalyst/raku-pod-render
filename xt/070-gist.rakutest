use Test;

use ProcessedPod;
my ProcessedPod $pp .= new;

like $pp.pod-file.gist,
        /
        'renderedtime => Str=｢｣'
        .+ 'templates-used => No templates used'
        /, 'blank PodFile gist';

use Pod::To::HTML2; # to incorporate consistent templates

my Pod::To::HTML2 $p .= new;

=begin pod
    my $d = 'one two three';

=head1 A title

=defn the
definite article

=end pod

$p.process-pod($=pod[0]);
$p.source-wrap;

my $pf = $p.emit-and-renew-processed-state;
like $pf.gist,
    /
        ':target("A_title"),'
        \s+ ':text("A title")'
    /, 'reasonable PodFile gist';

done-testing;
