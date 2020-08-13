use Test;
use Test::Deeply::Relaxed;
use ProcessedPod;

plan 3;

my $rv;
my $pro = ProcessedPod.new;
my $pv = 0;

my @templates = <raw comment escaped glossary footnotes head header footer declarator dlist-start dlist-end
            format-c block-code format-u para format-b named source-wrap defn output format-l
            format-x heading title format-n format-i format-k format-p meta list subtitle format-r
            format-t table item notimplemented section toc pod >;
my %templates  = @templates Z=> ( "\<$_>\{\{\{ contents }}}\</$_>" for @templates );
$pro.templates(%templates);

=begin pod  :kind("Language") :subkind("Language") :category("fundamental")

=TITLE testing

=SUBTITLE more tests

Stuff

=end pod

$pro.render-block( $=pod[$pv++] );
is-deeply-relaxed $pro.pod-config-data, %( :kind<Language>, :subkind<Language>, :category<fundamental>), 'got pod config data';

=begin pod  :different<This is different> :difficult<shouldnt be>

=TITLE testing again

=SUBTITLE more tests

Stuff and Nonsense

=end pod

$pro.render-block( $=pod[$pv]) ;
isnt-deeply-relaxed $pro.pod-config-data, %( :different<This is different>, :difficult<shouldnt be> ), 'only first config data allowed';

$pro.emit-and-renew-processed-state;

$pro.render-block( $=pod[$pv]) ;
is-deeply-relaxed $pro.pod-config-data, %( :different("This is different"), :difficult("shouldnt be") ), 'second block config data accepted';

done-testing;
