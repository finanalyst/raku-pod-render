use v6.*;
use Test;

use ProcessedPod;

plan 3;

my ProcessedPod $pro;

my $tmpl-fn = 't/newtemplates.raku';
$tmpl-fn.IO.unlink if $tmpl-fn.IO.f;

my @templates = <block-code comment declarator defn dlist-end dlist-start escaped footnotes format-b format-c
        format-i format-k format-l format-n format-p format-r format-t format-u format-x glossary heading
        item list meta named output para pod raw source-wrap table toc >;

my %templates  = @templates Z=> ( "\<$_>\{\{\{ contents }}}\</$_>" for @templates );
%templates<format-b> = '<new-form-b>{{ contents }}</new-form-b>';
$pro .= new(:name<Testing> );

$tmpl-fn.IO.spurt(%templates.raku.substr(0, *-3 ) );

dies-ok { $pro.templates($tmpl-fn) }, 'bad template is trapped' ;

$tmpl-fn.IO.spurt(%templates.raku );

lives-ok { $pro.templates($tmpl-fn) }, 'accepts a template file';

like $pro.rendition('format-b', %(:contents('Hello world'))),
        / '<new-form-b>' 'Hello world' '</new-form-b>' /, 'basic interpolation correct from file';

$tmpl-fn.IO.unlink if $tmpl-fn.IO.f;

done-testing;
