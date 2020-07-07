use v6.*;
use Test;

use Pod::To::HTML;
my $processor = Pod::To::HTML.new;
my $rv;
my $pn = 0;

plan 9;

=begin pod
=TITLE This is a title

Some text

=end pod

$rv = $processor.render-block( $=pod[$pn++] );

like $rv,
        /
        '<section'
        .+? '<h1 class="title" id="This_is_a_title">This is a title</h1>'  # the first header id
        \s* '<p>Some text</p>'
        \s* '</section>'
        /,
        'pod with title rendered';

$rv = $processor.source-wrap;
like $rv,
        /
        '<section'
        .+? '<h1 class="title" id="This_is_a_title">This is a title</h1>'  # the first header id
        \s* '<p>Some text</p>'
        \s* '</section>'
        /,
        'pod with title rendered, target rewritten for source-wrap';

=begin pod
=TITLE A Second Pod File

=SUBTITLE This is subtitled for testing

Some more text

=head2 This is a heading

Some text after a heading

=head1 An upper heading after a second level one

text

=head2 A lower heading within upper one

=end pod

$processor.delete-pod-structure;
$rv = $processor.render-block( $=pod[$pn++] );

like $rv, /
        '<h1 class="title" id="A_Second_Pod_File">A Second Pod File</h1>'
        \s* '<div class="subtitle">'
        \s* '<p>This is subtitled for testing</p>'
        .+ '<p>Some more text</p>'
        \s* '<h2 id="This_is_a_heading"><a href="#A_Second_Pod_File" class="u" title="go to top of document">This is a heading</a></h2>'
        \s* '<p>Some text after a heading</p>'
        /, 'subtitle rendered';

$rv = $processor.source-wrap;

like $rv,
        /
        '<table id="TOC">'
        \s* '<caption>Table of Contents</caption>'
        \s* '<tr class="toc-level-2">'
        \s* '<td class="toc-text"><a href="#This_is_a_heading"><span class="toc-counter">0.1</span> This is a heading</a></td>'
        \s* '</tr>'
        \s* '<tr class="toc-level-1">'
        \s* '<td class="toc-text"><a href="#An_upper_heading_after_a_second_level_one">'
        '<span class="toc-counter">1</span> An upper heading after a second level one</a></td>'
        \s* '</tr>'
        \s* '<tr class="toc-level-2">'
        \s* '<td class="toc-text"><a href="#A_lower_heading_within_upper_one">'
        \s* '<span class="toc-counter">1.1</span> A lower heading within upper one</a>'
        \s* '</td>'
        \s* '</tr>'
        \s* '</table>'
        /
        , 'rendered TOC';
$processor.counter-separator = '|';
$rv = $processor.render-toc;

like $rv,
        /
        '<table id="TOC">'
        \s* '<caption>Table of Contents</caption>'
        \s* '<tr class="toc-level-2">'
        \s* '<td class="toc-text"><a href="#This_is_a_heading"><span class="toc-counter">0|1</span> This is a heading</a></td>'
        /
        , 'TOC has new heading separator';

$processor.no-counters = True;
$rv = $processor.render-toc;

like $rv,
        /
        '<table id="TOC">'
        \s* '<caption>Table of Contents</caption>'
        \s* '<tr class="toc-level-2">'
        \s* '<td class="toc-text"><a href="#This_is_a_heading"> This is a heading</a></td>'
        \s* '</tr>'
        \s* '<tr class="toc-level-1">'
        \s* '<td class="toc-text"><a href="#An_upper_heading_after_a_second_level_one">'
        \s* 'An upper heading after a second level one</a></td>'
        \s* '</tr>'
        \s* '<tr class="toc-level-2">'
        \s* '<td class="toc-text"><a href="#A_lower_heading_within_upper_one">'
        \s* 'A lower heading within upper one</a>'
        \s* '</td>'
        \s* '</tr>'
        \s* '</table>'
        /
        , 'TOC has no Heading counters';

$processor.no-toc = True;
$rv = $processor.render-toc;

unlike $rv,
        /
        '<table id="TOC">'
        /, 'TOC not rendered';

=begin pod

=head1 Heading 1

=head2 Heading 1.1

=head2 Heading 1.2

=head1 Heading 2

=head2 Heading 2.1

=head2 Heading 2.2

=head2 L<(Exception) method message|/routine/message#class_Exception>

=head3 Heading 2.2.1

=head3 X<Heading> 2.2.2

Note that only the word Heading is indexed

=head1 Heading C<3>

=end pod

$processor.delete-pod-structure;
$processor.process-pod( $=pod[$pn++] );
$rv = $processor.source-wrap;

like $rv, /'h2 id="Heading_2.2"' .+ '>Heading 2.2'/, 'Heading 2.2 has expected id';

like $rv, /'class="glossary-entry">Heading' .+ '2.2.2</a>' / , 'Heading 2.2.2 is in glossary as well';
