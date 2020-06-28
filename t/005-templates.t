use v6.*;
use Test;

use ProcessedPod;

plan 5;

my $tmpl-fn = 't/newtemplates.raku';
$tmpl-fn.IO.unlink if $tmpl-fn.IO.f;

my ProcessedPod $pro;

throws-like { $pro .= new },
        X::ProcessedPod::MissingTemplates,
        message=>/'The following templates should be supplied'/,
        "Catches the absence of templates";

my @templates = <raw comment escaped glossary footnotes
            format-c block-code format-u para format-b named source-wrap defn output format-l
            format-x heading title format-n format-i format-k format-p meta list subtitle format-r
            format-t table item notimplemented section toc>;

my %templates = @templates Z=> ( "[beg]$_\[end]" for @templates );
        # this creates a set of pseudo templates

lives-ok { $pro .= new(:%templates) }, 'lives when given a full list of templates';

%templates<format-c>:delete; # assumes toc is a required template

throws-like { $pro .=new(:%templates) }, X::ProcessedPod::MissingTemplates,
        message=> / 'but are not:' \s* 'format-c' \s* /,
        "Catches the missing template";

# testing with the default Mustache::Template.

%templates  = @templates Z=> ( "\<$_>\{\{\{ contents }}}\</$_>" for @templates );

$pro .= new(:%templates, :name<Testing> );

like $pro.rendition('format-b', %(:contents('Hello world'))),
        / '<format-b>' 'Hello world' '</format-b>' /, 'basic interpolation correct';

$pro.replace-template( %( format-b => -> %params { '#' x %params<level> ~ ' {{ text }}' ~ "\n" }));

like $pro.rendition('format-b', %(:text('Hello World'), :level(5) )),
        / \# **5 \s* 'Hello World' /, 'template replaced, and pointy routine accepted as a template';

done-testing;