use v6.*;
use Test;

use ProcessedPod;

plan 22;

my ProcessedPod $pro;

throws-like { $pro .= new },
        X::ProcessedPod::MissingTemplates,
        message=>/'The following templates should be supplied'/,
        "Catches the absence of templates";

my @templates = <raw comment escaped glossary footnotes glossary-heading
            format-c block-code format-u para format-b named source-wrap defn output format-l
            format-x heading title format-n format-i format-k format-p meta list subtitle format-r
            format-t table item notimplemented glossary-entry section toc>;
my %tmpl = @templates Z=> ( "[beg]$_\[end]" for @templates );
        # this creates a set of pseudo templates

lives-ok { $pro .= new(:%tmpl) }, 'lives when given a full list of templates';

my $top = @templates.pop;
%tmpl = @templates Z=> ( "[beg]$_\[end]" for @templates );
        # one less template

throws-like { $pro .=new(:%tmpl) }, X::ProcessedPod::MissingTemplates,
        message=> / 'but are not:' \s* <$top> \s* /,
        "Catches the missing template";

# testing with the default Mustache::Template.

@templates.push: $top;
%tmpl  = @templates Z=> ( 'Before {{{ content }}} After' for @templates );

$pro .= new(:%tmpl, :name<Testing> );

like $pro.rendition('format-b', %(:content('Hello world'))),
        / 'Before ' 'Hello world' ' After' /, 'basic interpolation correct';

$pro.replace-template( %( format-b => -> %params { say 'in format routine'; '#' x %params<level> ~ ' {{ text }}' ~ "\n" }));

like $pro.rendition('format-b', %(:text('Hello World'), :level(5) )),
        / \# **5 \s* 'Hello World' /, 'template replaced, and pointy routine accepted as a template';

# the following pod creates Footnotes, Meta, TOC and Glossary structures, which will only render minimally as above,
# Actual rendering will be tested in html tests.

=begin pod

=TITLE testing

=SUBTITLE more tests

=AUTHOR An author is named

=SUMMARY This page is about Raku

When indexing X<an item|Define an item> another text can be used for the index.

=head1 Heading 1

This text has footnotes and indexed items. Some thing to say N<A footnote> in between words.

=head2 Heading 1.1

=head2 Heading 1.2

=head1 Heading 2

=head2 Heading 2.1

It is possible to index X<hierarchical items|defining,a term>with hierarchical levels.

And then index the X<same place|Same,almost;Place> with different index entries.

But X<|an entry can exist> without the text being marked.

An empty X<> is ignored.
=end pod

lives-ok { $pro.render-block( $=pod ) }, 'main processing methods work, not interested in return values yet';

my %pod-structure;
lives-ok { %pod-structure = $pro.delete-pod-structure}, 'deletion method lives';

for <name title subtitle metadata toc glossary footnotes body path renderedtime >
{
        ok %pod-structure{$_} ne '', "$_ has content";
}

for <metadata toc footnotes glossary>
{
        ok +%pod-structure{"raw-$_"}, "raw-$_ has content"
}

nok $pro.renderedtime.defined, 'time should be undefined after a delete-pod-structure';

done-testing;
