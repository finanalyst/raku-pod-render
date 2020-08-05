use v6.*;
use Test;

use Pod::To::MarkDown;
my $processor = Pod::To::MarkDown.new;
my $rv;
my $pn = 0;

plan 3;
=table
  col1  col2

$rv = $processor.render-block( $=pod[$pn++] );

like $rv,
    /
    '|' \s* 'col1' \s* '|' \s* 'col2' \s* '|'
    /, 'simple row';

=table
  H1    H2
  --    --
  col1  col2

$rv = $processor.render-block( $=pod[$pn++] );

like $rv,
    /
    '|' \s* 'H1' \s* '|' \s* 'H2' \s* '|'
    \s* '|:----:|:----:|'
    \s* '|' \s* 'col1' \s* '|' \s* 'col2' \s* '|'
    /,'simple header and row';

=begin table :caption<Test Caption>

  H1    H2
  --    --
  col1  col2

  col1  col2

  col1  col2

=end table

$rv = $processor.render-block( $=pod[$pn++] );

like $rv,
    /
    '>Test Caption'
    \v \s* '|' \s* 'H1' \s* '|' \s* 'H2' \s* '|'
    \s* '|:----:|:----:|'
    \s* '|' \s* 'col1' \s* '|' \s* 'col2' \s* '|'
    \s* '|' \s* 'col1' \s* '|' \s* 'col2' \s* '|'
    \s* '|' \s* 'col1' \s* '|' \s* 'col2' \s* '|'
    /, 'table with caption rows';
