use v6.d;
use Test;
use ProcessedPod;
use RenderPod::Templating;
use Test::Output;
plan 7;

my $tmpl-fn = 'xt/newtemplates.raku';
$tmpl-fn.IO.unlink if $tmpl-fn.IO.f;

my ProcessedPod $pro .= new;

my @templates = <block-code comment declarator defn dlist-end dlist-start escaped footnotes format-b format-c
        format-i format-k format-l format-n format-p format-r format-t format-u format-x glossary heading
        item list meta named output para pod raw source-wrap table toc >;

# test for Cro Templates
my %templates = @templates Z=> ( "\[beg]<.contents>$_\[end]" for @templates );
lives-ok { $pro.templates(%templates) }, 'loads templates';
isa-ok $pro.templater, 'CroTemplater', 'auto-detects Cro templater';

$pro .= new;
%templates<_templater> = 'NotKnownTemplater';
throws-like { $pro.templates(%templates) }, X::ProcessedPod::UnknownTemplatingEngine,
        message => / 'Can\'t create template engine ｢NotKnownTemplater｣' /,
        'Catches unknown templater';

$pro .= new;
%templates<_templater> = 'CroTemplater';
lives-ok { $pro.templates(%templates) }, 'loads templates';
isa-ok $pro.templater, 'CroTemplater', 'auto-detects Cro templater';

$pro .= new;
%templates<_templater> = 'MustacheTemplater';
lives-ok { $pro.templates(%templates) }, 'loads templates';
isa-ok $pro.templater, 'MustacheTemplater', '_templater key overides autodetection';

done-testing