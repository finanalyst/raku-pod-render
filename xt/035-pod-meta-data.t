use Test;
use Test::Deeply::Relaxed;
use ProcessedPod;
use RenderPod::Templating;

plan 4;

my $rv;
my $pro = ProcessedPod.new;
my $pv = 0;

my @templates = <block-code comment declarator defn dlist-end dlist-start escaped footnotes format-b format-c
        format-i format-k format-l format-n format-p format-r format-t format-u format-x glossary heading
        item list meta named output para pod raw source-wrap table toc >;

my %templates  = @templates Z=> @templates.map( { gen-closure-template( $_ ) });
%templates<escaped> = sub ($s) { $s };
%templates<meta> = sub ( %prm, %tmp ) {
    "<meta>\n"
    ~ %prm<meta>.map( { $_<name> ~ '=' ~ $_<value> ~ "\n"} )
    ~ '</meta>'
};
%templates<source-wrap> = sub (%prm, %tml ) { "<file><body>{ %prm<body> }</body>{ %prm<metadata> }</file>"};

$pro.templates(%templates);

=begin pod  :kind("Language") :subkind("Language") :category("fundamental")

=TITLE testing

=SUBTITLE more tests

Stuff

=end pod

$pro.render-block( $=pod[$pv++] );

is-deeply-relaxed $pro.pod-file.pod-config-data, %( :kind<Language>, :subkind<Language>, :category<fundamental>), 'got pod config data';

=begin pod  :different<This is different> :difficult<shouldnt be>

=TITLE testing again

=SUBTITLE more tests

Stuff and Nonsense

=end pod

$pro.render-block( $=pod[$pv]) ;
isnt-deeply-relaxed $pro.pod-file.pod-config-data, %( :different<This is different>, :difficult<shouldnt be> ), 'only first config data allowed';

$pro.emit-and-renew-processed-state;

$pro.render-block( $=pod[$pv]) ;
is-deeply-relaxed $pro.pod-file.pod-config-data, %( :different("This is different"), :difficult("shouldnt be") ), 'second block config data accepted';

=begin pod
=AUTHOR A.N. Writer
=SUMMARY Some summerised remarks

Stuff

=end pod

$pro.emit-and-renew-processed-state;
$pro.render-tree( $=pod[++$pv] );
like $pro.source-wrap,
        /
        '<file><body>'
        .+ 'Stuff'
        .+ '</body>'
        '<meta>'
        [ \s* 'Author=A.N. Writer' | \s* 'Summary=Some summerised remarks' ] **2
        \s* '</meta></file>'
        /, 'Got meta data structure';
done-testing;
