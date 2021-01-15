use v6.*;
use Test;

use ProcessedPod;

plan 3;

my ProcessedPod $pro;

my $tmpl-fn = 'newtemplates.raku';
my $path = 'xt';
"$path/$tmpl-fn".IO.unlink if "$path/$tmpl-fn".IO.f;

my @templates = <block-code comment declarator defn dlist-end dlist-start escaped footnotes format-b format-c
        format-i format-k format-l format-n format-p format-r format-t format-u format-x glossary heading
        item list meta named output para pod raw source-wrap table toc >;

my %templates  = @templates Z=> ( "\<$_>\{\{\{ contents }}}\</$_>" for @templates );
%templates<format-b> = '<new-form-b>{{ contents }}</new-form-b>';
$pro .= new(:name<Testing> );

"$path/$tmpl-fn".IO.spurt(%templates.raku.substr(0, *-3 ) );

dies-ok { $pro.templates( $tmpl-fn,:$path ) }, 'bad template is trapped' ;

"$path/$tmpl-fn".IO.spurt(%templates.raku );

lives-ok { $pro.templates($tmpl-fn, :$path ) }, 'accepts a template file';

like $pro.rendition('format-b', %(:contents('Hello world'))),
        / '<new-form-b>' 'Hello world' '</new-form-b>' /, 'basic interpolation correct from file';

"$path/$tmpl-fn".IO.unlink if "$path/$tmpl-fn".IO.f;

done-testing;
