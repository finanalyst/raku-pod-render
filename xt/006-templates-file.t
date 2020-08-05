use v6.*;
use Test;

use ProcessedPod;

plan 3;

my ProcessedPod $pro;

my $tmpl-fn = 't/newtemplates.raku';
$tmpl-fn.IO.unlink if $tmpl-fn.IO.f;

my @templates = <raw comment escaped glossary footnotes head header footer declarator dlist-start dlist-end
            format-c block-code format-u para format-b named source-wrap defn output format-l
            format-x heading title format-n format-i format-k format-p meta list subtitle format-r
            format-t table item notimplemented section toc pod >;

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
