use Test;
use Test::Deeply::Relaxed;
use ProcessedPod;

plan 12;

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

lives-ok { $pro.render-block( $=pod[0] ); $pro.source-wrap; }, 'main processing methods work, not interested in return values yet';

my $pod-structure;
lives-ok { $pod-structure = $pro.emit-and-renew-processed-state}, 'renew method lives';

for $pod-structure.^methods.grep({
    .name ~~ any(<name title renderedtime subtitle >)
}) { ok $_($pod-structure) ne '', $_.name ~' has content' };

for $pod-structure.^methods.grep({
    .name ~~ any(< raw-metadata raw-toc raw-glossary raw-footnotes >)
}) { ok $_($pod-structure).elems, $_.name ~' has elements' };

is-deeply-relaxed $pod-structure.templates-used.BagHash,
        ("pod"=>1,"heading"=>5,"zero"=>22,"para"=>7,"format-x"=>4,"format-n"=>1,"raw"=>5,"escaped"=>22,
        :1footnotes, :1glossary, :1source-wrap, :1meta, :1toc).BagHash,
        'used the expected templates';

is $pro.pod-file.renderedtime, '', 'time should be blank after a emit-and-renew-processed-state';

done-testing;
