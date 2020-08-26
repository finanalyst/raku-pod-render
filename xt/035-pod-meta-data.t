use Test;
use Test::Deeply::Relaxed;
use ProcessedPod;

plan 3;

my $rv;
my $pro = ProcessedPod.new;
my $pv = 0;

my @templates = <block-code comment declarator defn dlist-end dlist-start escaped footnotes format-b format-c
        format-i format-k format-l format-n format-p format-r format-t format-u format-x glossary heading
        item list meta named output para pod raw source-wrap table toc >;

my %templates  = @templates Z=> @templates.map( { gen-closure-template( $_ ) });
%templates<escaped> = sub ($s) { $s };

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
