use v6.*;
use Test;

use ProcessedPod;

plan 2;

my ProcessedPod $pro;

throws-like { $pro .= new },
        X::ProcessedPod::MissingTemplates,
        message=>/'The following templates should be supplied'/,
        "Catches the absence of templates";

my @templates = <raw comment escaped glossary footnotes glossary-heading
            format-c block-code format-u para format-b named source-wrap defn output format-l
            format-x heading title format-n format-i format-k format-p meta list subtitle format-r
            format-t table item notimplemented glossary-entry section toc>;
my $top = @templates.pop;

my %tmpl = @templates Z=> ( "[beg]$_\[end]" for @templates );
        # this creates a set of pseudo templates

throws-like { $pro .=new(:%tmpl) }, X::ProcessedPod::MissingTemplates,
        message=> / 'but are not:' \s* <$top> \s* /,
        "Catches the missing template";

# we could test all the various POD behaviours here, but they are tested for HTML.

done-testing;
