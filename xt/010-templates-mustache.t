use v6.*;
use Test;

use ProcessedPod;

plan 7;

my $tmpl-fn = 't/newtemplates.raku';
$tmpl-fn.IO.unlink if $tmpl-fn.IO.f;

my $pro;

lives-ok { $pro = ProcessedPod.new }, 'instantiates';

my $pod = Pod::FormattingCode.new(:type('B'), :contents(['hello world']));

throws-like { $pro.render-block($pod) },
        X::ProcessedPod::MissingTemplates,
        message=>/'No templates loaded'/,
        "Catches the absence of templates";

my @templates = <block-code comment declarator defn dlist-end dlist-start escaped footnotes format-b format-c
        format-i format-k format-l format-n format-p format-r format-t format-u format-x glossary heading
        item list meta named output para pod raw source-wrap table toc >;

my %templates = @templates Z=> ( "[beg]$_\[end]" for @templates );
        # this creates a set of pseudo templates

%templates<format-c>:delete; # assumes toc is a required template

throws-like { $pro.templates(%templates) }, X::ProcessedPod::MissingTemplates,
        message=> / 'but are not:' \s* 'format-c' \s* /,
        "Catches the missing template";

# testing with Mustache::Template.
$pro = ProcessedPod.new;

%templates  = @templates Z=> ( "\<$_>\{\{\{ contents }}}\</$_>" for @templates );

lives-ok { $pro.templates(%templates) }, 'full set of templates is ok';

like $pro.rendition('format-b', %(:contents('Hello world'))),
        / '<format-b>' 'Hello world' '</format-b>' /, 'basic interpolation correct';

$pro.modify-templates( %( format-b => -> %params { '#' x %params<level> ~ ' {{ text }}' ~ "\n" }));

like $pro.rendition('format-b', %(:text('Hello World'), :level(5) )),
        / \# **5 \s* 'Hello World' /, 'template replaced, and pointy routine accepted as a template';

$pro.modify-templates( %(:newone('<container>{{ contents }}</container>'),
                       :format-b('{{> newone }} is wrapped')) );
like $pro.rendition('format-b', %(:contents('Hello world'))),
        / '<container>' 'Hello world' '</container> is wrapped' /, 'interpolation with partials correct';

done-testing;