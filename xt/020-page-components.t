use Test;
use ProcessedPod;

plan 17;

my ProcessedPod $pro .= new;

my @templates = <raw comment escaped glossary footnotes head header footer declarator dlist-start dlist-end
            format-c block-code format-u para format-b named source-wrap defn output format-l
            format-x heading title format-n format-i format-k format-p meta list subtitle format-r
            format-t table item notimplemented section toc pod >;

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

my %templates  = @templates Z=> ( "\<$_>\{\{\{ contents }}}\</$_>" for @templates );

$pro.templates(%templates);

lives-ok { $pro.render-block( $=pod[0] ) }, 'main processing methods work, not interested in return values yet';

my %pod-structure;
lives-ok { %pod-structure = $pro.emit-and-renew-processed-state}, 'renew method lives';

for <name title subtitle metadata toc glossary footnotes body path renderedtime >
{
    ok %pod-structure{$_} ne '', "$_ has content";
}

for <metadata toc footnotes glossary>
{
    ok +%pod-structure{"raw-$_"}, "raw-$_ has content"
}

nok $pro.renderedtime.defined, 'time should be undefined after a emit-and-renew-processed-state';


done-testing;
