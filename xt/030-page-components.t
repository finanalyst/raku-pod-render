use Test;
use Test::Deeply::Relaxed;
use ProcessedPod;

plan 18;

my ProcessedPod $pro .= new;

my @templates = <block-code comment declarator defn dlist-end dlist-start escaped footnotes format-b format-c
        format-i format-k format-l format-n format-p format-r format-t format-u format-x glossary heading
        item list meta named output para pod raw source-wrap table toc >;

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

is-deeply-relaxed %pod-structure<templates-used>,
        ("pod"=>1,"glossary"=>1,"heading"=>5,"zero"=>22,"para"=>7,"format-x"=>4,"footnotes"=>1,"meta"=>1,"format-n"=>1,"raw"=>5,"toc"=>1,"escaped"=>22).BagHash,
        'used the expected templates';

nok $pro.renderedtime, 'time should be blank after a emit-and-renew-processed-state';

done-testing;
