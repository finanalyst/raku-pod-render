use v6.*;
use Test;

use Pod::To::HTML;
my $processor = Pod::To::HTML.processor;
my $rv;
my $pn = 0;

plan 7;

=begin pod
=TITLE This is a title

Some text

=end pod

$processor.process-pod( $=pod[$pn++] );
$rv = $processor.body-only;

like $rv,
        /
        '<section name="___top">'
                \s* '<h1 class="title" id="this_is_a_title">This is a title</h1>'  # the first header id
                \s* '<p>Some text</p>'
                \s* '</section>'
        /,
        'pod with title rendered';

$rv = $processor.source-wrap;
like $rv,
        /
        '<section name="___top">'
                \s* '<h1 class="title" id="this_is_a_title">This is a title</h1>'  # the first header id
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

=end pod

$processor = Pod::To::HTML.processor; # re-instantiate to clear previous headings
$processor.process-pod( $=pod[$pn++] );
$rv = $processor.body-only;

like $rv, /
        '<h1 class="title" id="a_second_pod_file">A Second Pod File</h1>'
        \s* '<div class="subtitle">'
        \s* '<p>This is subtitled for testing</p>'
        .+ '<p>Some more text</p>'
        \s* '<h2 id="this_is_a_heading"><a href="#a_second_pod_file" class="u" title="go to top of document">This is a heading</a></h2>'
        \s* '<p>Some text after a heading</p>'
        /, 'subtitle rendered';

$rv = $processor.source-wrap;

like $rv,
        /
        '<table id="TOC">'
                \s* '<caption>'
                \s* '<h2 id="TOC_Title">Table of Contents</h2></caption>'
                \s* '<tr class="toc-level-2">'
                \s* '<td class="toc-text">'
                \s* '<a href="#this_is_a_heading">This is a heading</a>'
                \s* '</td>'
                \s* '</tr>'
                \s* '</table>'
        /
        , 'rendered TOC';

$processor.no-toc = True;
$rv = $processor.source-wrap;

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

=head1 Heading C<3>

=end pod

$processor = Pod::To::HTML.processor; # re-instantiate to clear previous headings
$processor.process-pod( $=pod[$pn++] );
$rv = $processor.source-wrap
        .subst(/\s+/,' ',:g).trim;

like $rv, /'h2 id="heading_2.2"' .+ '>Heading 2.2'/, 'Heading 2.2 has expected id';

like $rv, /'class="glossary-entry">Heading' .+ '2.2.2</a>' / , 'Heading 2.2.2 is in glossary as well';