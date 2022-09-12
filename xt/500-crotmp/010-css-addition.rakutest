use Test;
use Pod::To::HTML2;
my $rv;
my $processor;

plan 13;

unless %*ENV<CROTMP> {
    skip-rest "Only use these tests if CROTMP is set in ENV";
    exit
};


=begin pod
Some pod
=end pod

throws-like { $processor = Pod::To::HTML2.new(:css-type<link>,:type<crotmp>) },
        X::ProcessedPod::HTML::InvalidCSS::NoSpec,
        message=>/'If :css-type is supplied'/,
        "Catches the absence of :css-src";
throws-like { $processor = Pod::To::HTML2.new(:css-type<load>, :css-src('assets/xxpod.css'),:type<crotmp> ) },
        X::ProcessedPod::HTML::InvalidCSS::BadSource,
        message=>/'assets/xxpod.css does not exist as a text file'/,
        "Catches bad file";
throws-like { $processor = Pod::To::HTML2.new(:css-type<other>, :css-src<Something>,:type<crotmp>) },
        X::ProcessedPod::HTML::InvalidCSS::BadType,
        message=>/'Only \'load\' or \'link\' acceptable, got \'other\''/,
        "Catches bad css-type";
my $link = 'https://raku.org/docs/pod.css';
lives-ok { $processor = Pod::To::HTML2.new(:css-type<link>, :css-src($link),:type<crotmp>) }, 'valid :css-type<link> and :css-src work';
$rv = $processor.source-wrap;
like $rv, /
    '<head' .+ '<link rel="stylesheet"' \s+ 'type="text/css" href="'
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
lives-ok { $processor = Pod::To::HTML2.new(:css-type<load>, :css-src($fn),:type<crotmp>) }, 'valid :css-type<load> and :css-src work';
$fn.IO.unlink if $fn.IO.e;
$rv = $processor.source-wrap;
like $rv, /
'<head' .+ '<style' .+
'color:blue'
.+ '</style>'
/, 'Style has been brought in';

lives-ok { $processor = Pod::To::HTML2.new(:css-url<assets/css/pod.css>,:type<crotmp>) }, 'css-url works';
$rv = $processor.source-wrap;
like $rv, /
    '<head' .+ '<link rel="stylesheet"' .+ 'href="'
    'assets/css/pod.css'
    /, 'Alternative link via legacy css';

'favicon-new'.IO.unlink; # clear up
throws-like { $processor = Pod::To::HTML2.new(:favicon-src('favicon-new'),:type<crotmp>) }, X::ProcessedPod::HTML::BadFavicon,
        'Traps non-existent favicon file', message => / 'The favicon source is unavailable' /;

'favicon-new'.IO.spurt('This favicon will not work in HTML but will be put into head');

lives-ok { $processor = Pod::To::HTML2.new(:favicon-src('favicon-new'),:type<crotmp>) }, 'favicon file now exists';

$processor.render-tree($=pod);
$rv = $processor.source-wrap;
like $rv, /
    '<head' .+ 'href="data:image/x-icon;base64,This favicon will not work in HTML but will be put into head" rel="icon"'
    /, 'New favicon inserted';

'favicon-new'.IO.unlink; # clear up
$processor = Pod::To::HTML2.new(:type<crotmp>);
$processor.css = 'some-other.css';
$rv = $processor.source-wrap;
like $rv, /
    '<head' .+ '<link rel="stylesheet"' .+ 'href="'
    'some-other.css'
/, 'New link rendered';

done-testing;
