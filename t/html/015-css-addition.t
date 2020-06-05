use Test;
use Pod::To::HTML;
my $rv;
my $processor;

plan 7;

=begin pod
    Some pod
=end pod

throws-like { $processor = Pod::To::HTML.processor(:css<link>) },
        X::ProcessedPod::HTML::InvalidCSS::NoSpec,
        message=>/'If :css is supplied'/,
        "Catches the absence of :src";
throws-like { $processor = Pod::To::HTML.processor(:css<load>, :src('assets/xxpod.css') ) },
        X::ProcessedPod::HTML::InvalidCSS::BadSource,
        message=>/'assets/xxpod.css does not exist as a text file'/,
        "Catches bad file";
throws-like { $processor = Pod::To::HTML.processor(:css<other>, :src<Something>) },
        X::ProcessedPod::HTML::InvalidCSS::BadType,
        message=>/'Only \'load\' or \'link\' acceptable, got \'other\''/,
        "Catches bad css type";
my $link = 'https://raku.org/docs/pod.css';
lives-ok { $processor = Pod::To::HTML.processor(:css<link>, :src($link)) }, 'valid :css<link> and :src work';
$rv = $processor.source-wrap;
like $rv, /
    '<head' .+ '<link rel="stylesheet"  type="text/css" href="'
    $link
    '" media="screen" title="default" />'
/, 'A stylesheet link has been included';

my $fn = 't/tmppod.css';
$fn.IO.unlink if $fn.IO.e;
$fn.IO.spurt: q:to/CSSEND/;
    table#TOC code {
     color:blue;
    }
    CSSEND
lives-ok { $processor = Pod::To::HTML.processor(:css<load>, :src($fn)) }, 'valid :css<load> and :src work';
$fn.IO.unlink if $fn.IO.e;
$rv = $processor.source-wrap;
like $rv, /
'<head' .+ '<style' .+
'color:blue'
.+ '</style>'
/, 'Style has been brought in';

done-testing;
