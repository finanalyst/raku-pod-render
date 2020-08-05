=begin pod

=head1 NAME

Template::Classic - Templates with arbitrary Perl 6 code inside them

=head1 SYNOPSIS

    use Template::Classic;

    my &render-list := template :($title, @items), q:to/HTML/;
        <h1><%= $title %></h1>
        <ul>
            <% for @items -> $item { %>
                <li><%= $item %></li>
            <% } %>
        </ul>
        HTML

    print render-list(｢Shopping list｣,
                      [｢Cheese｣, ｢Bacon｣]);

=head1 DESCRIPTION

Templates are strings with C«<% %>»-delimited snippets of Perl 6 code inside
them. Embedded Perl 6 code can use I«take» to emit strings into the rendered
template. In addition, C«<%= %>» delimiters can be used to emit the result of
evaluating an expression. This value is converted to a string by calling its
I«.Str» method and special HTML characters are escaped.

=end pod

unit module Template::Classic;

use MONKEY-SEE-NO-EVAL;

my grammar Grammar
{
    token TOP
    {
        ^
        [
            $<part> = <text> ||
            $<part> = <code> ||
            # TODO: Throw X::Template::Classic, not X::AdHoc.
            <!before $> {die ｢Unterminated <%｣ }
        ]*
        $
    }

    token text
    {
        [ <!before ‘<%’> . ]+
    }

    token code
    {
        ‘<%’ [ $<put> = ‘=’ ]?
            $<source> = [ <!before ‘%>’> . ]*
        ‘%>’
    }
}

my class Actions
{
    method TOP($/)
    {
        make qq｢lazy gather \{ {$<part>.map({.made ~ “\n”}).join} \}｣;
    }

    method text($/)
    {
        make qq｢take {$/.Str.perl};｣;
    }

    method code($/)
    {
        if $<put> {
            make qq｢take(Template::Classic::escape(do \{ {$<source>} \}));｣;
        } else {
            make qq｢$<source>;｣;
        }
    }
}

#| Compile a template into a subroutine with the given signature. Parameters
#| specified in the signature are available within the template.
sub template(Signature:D $sig, Str:D $source --> Routine:D)
    is export
{
    my $compiled := Grammar.parse($source, actions => Actions).made;

    # There is a bug in Rakudo that prevents us from directly using EVAL when
    # template is called at the top-level of a comp unit. Thus, we compile the
    # template lazily; the first time it is called.
    # See also: https://github.com/rakudo/rakudo/issues/3096.
    my &subroutine;
    sub (|c) {
        without &subroutine {
            &subroutine = EVAL qq｢sub {$sig.perl.substr(1)} \{ $compiled \}｣;
        }
        &subroutine(|c);
    }
}

#| Translate <, >, &, ", ' to their corresponding entities. The former three 
#| are translated to avoid conflict with tags and entities. The latter two are
#| translated to avoid conflict with attribute value delimiters.
our sub escape(Str() $_ --> Str:D)
{
    .trans: qw｢ <    >    &     "      '     ｣ =>
            qw｢ &lt; &gt; &amp; &quot; &#39; ｣;
}

=begin pod

=head1 BUGS

Due to a bug in Rakudo this module compiles the template only on the first
call to the template, rather than immediately when I«template» is called.
This will be fixed in a future version and must not be relied upon.

=end pod

sub emit-pod is export { $=pod }