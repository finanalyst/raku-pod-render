use v6.d;
use RenderPod::Exceptions;
use JSON::Fast;
use File::Temp;
=begin pod
This module adds highlighting functionality to ProcessedPod.

Highlighting at the time of writing is only available via a Samantha McVeigh's node
dependent system
and only for HTML. However, it should be made available using a Raku system
and for other rendered formats.

Highlighting is normally only needed for block code, rather than in-line code.

Highlighting should be separate from the templating system because it is output format
dependent, whilst the templating system should be output format neutral.

At the same time, extra wrapping formatting codes may be needed, so the highlighted
code should be sent to the templating engine.

Therefore, highlighting is added to ProcessedPod object, and a separate highlighted
field in the paramaters is created.
=end pod

role Highlighting is export {
    #| the output formatting.
    has $.format = 'HTML';
    =comment TODO Initially only HTML available. When others available add rw trait

    #| the highlighting engine, currently only Samantha McVie's atom engine
    has $.highlight-engine = 'atom';

    #| tells ProcessedPod not to escape characters when in a code block
    has Bool $.no-code-escape is rw is default(False) = False;
    =comment TODO this is a legacy of Pod::To::HTML and should be eliminated

    #| A boolean to indicate whether Raku should be highlighted
    has Bool $!highlight-code = False;
    #| The Asynchronous closure to provide the highlighting
    has Proc::Async $!external-highlighter;
    #| The connection to the highlighter
    has $!highlighter-supply;
    #| Path to where the highlighter executable (possibly non-Raku) is located
    has Str $!external-highlights-path;
    #| A function that takes a defined Str fragment and applies a highlight to it
    has &.insert-highlights is rw = -> Str:D $frag { $frag }; # default is to return $frag unchanged

    #| custom getter / setter
    method highlight-code ( ) is rw {
        Proxy.new(
            FETCH => -> $ { $!highlight-code },
            STORE => -> $, Bool $wanted-state {
                return if $wanted-state == $!highlight-code;
                my Bool $hlite;
                if $wanted-state {
                    # Toggle from OFF to on
                    # Uses Samantha McVie's atom-highlighter
                    # Raku-Pod-Render places this at <user-home>.local/share/raku-pod-render/highlights
                    # or <user-home>.raku-pod-render/highlights
                    given $.highlight-engine {
                        when 'atom' {
                            $!external-highlights-path = $.set-highlight-basedir
                            without $!external-highlights-path;
                            $!external-highlighter = Proc::Async.new(
                                    "{ $!external-highlights-path }/node_modules/coffeescript/bin/coffee",
                                    "{ $!external-highlights-path }/highlight-filename-from-stdin.coffee", :r, :w)
                            without $!external-highlighter;
                            $!highlighter-supply = $!external-highlighter.stdout.lines
                            without $!highlighter-supply;
                            # set up the highlighter closure
                            $.no-code-escape = True;
                            &.insert-highlights = -> $frag {
                                return $frag unless $frag ~~ Str:D;
                                $!external-highlighter.start unless $!external-highlighter.started;

                                my ($tmp_fname, $tmp_io) = tempfile;
                                # the =comment is needed to trigger the atom highlighter when the code isn't unambiguously Raku
                                $tmp_io.spurt: "=comment\n\n" ~ $frag, :close;
                                my $promise = Promise.new;
                                my $tap = $!highlighter-supply.tap(-> $json {
                                    my $parsed-json = from-json($json);
                                    if $parsed-json<file> eq $tmp_fname {
                                        $promise.keep($parsed-json<html>);
                                        $tap.close();
                                    }
                                });
                                $!external-highlighter.say($tmp_fname);
                                await $promise;
                                # get highlighted text remove raku trigger =comment
                                $promise.result.subst(/ '<div' ~ '</div>' .+? /, '', :x(2))
                            }
                            $hlite = True;
                        }
                        default {
                            note "$.highlight-engine was not found. No highlighting.";
                            # restore default code
                            &.insert-highlights = -> $frag { $frag };
                            $hlite = False;
                            $.no-code-escape = False;
                        }
                    }
                }
                else {
                    #toggle from ON to off
                    # restore default code
                    &.insert-highlights = -> $frag { $frag };
                    $hlite = False;
                    $.no-code-escape = False;
                }
                $!highlight-code = $hlite
            }
        )
    }

    method set-highlight-basedir( --> Str ) {
        my $basedir = $*HOME;
        my $hilite-path = "$basedir/.local/lib".IO.d
                ?? "$basedir/.local/lib/raku-pod-render/highlights".IO.mkdir
                !! "$basedir/.raku-pod-render/highlights".IO.mkdir;
        X::RenderPod::NoHighlightPath.new.throw
            unless ~$hilite-path;
        if $.highlight-engine eq 'atom' {
            X::RenderPod::NoAtomHighlighter.new.throw
                unless "$hilite-path/package-lock.json".IO.f and "$hilite-path/atom-language-perl6".IO.d
        }
        ~$hilite-path
    }
}
