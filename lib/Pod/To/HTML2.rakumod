use v6.d;
use ProcessedPod;
use RenderPod::Templating;
use RenderPod::Exceptions;
use RakuConfig;
use Pod::Load;

class Pod::To::HTML2 is ProcessedPod {
    # needed for HTML rendering
    has $.def-ext is rw = 'html';
    #| defaults directory
    has $.defaults = "$*HOME/.local/share/RenderPod".IO;

    # Only needed for legacy P2HTML
    has $!head = '';
    method head () is rw {
        Proxy.new(
            FETCH => -> $ { $!head },
            STORE => -> $, Str:D $head {
                $!head = $head;
                self.modify-templates(self.templater.make-template-from-string(
                        %( :$head,)
                    )
                );
            }
        )
    }
    has $!css = '';
    method css () is rw {
        Proxy.new(
            FETCH => -> $ { $!css },
            STORE => -> $, Str:D $css {
                $!css = $css;
                self.modify-templates(
                    self.templater.make-template-from-string(%(
                        :css("\<link rel=\"stylesheet\" href=\"$css>\">"),))
                )
            }
        )
    }

    #| render is a class method that is called by the raku compiler
    method render($pod-tree, :$def-dir) {
        state $rv;
        return $rv with $rv;
        # Some implementations of raku/perl6 called the classes render method twice,
        # so it's necessary to prevent the same work being done repeatedly
        my $pp = self.new(:$def-dir);
        $pp.pod-file.name = $*PROGRAM-NAME;
        # takes the pod tree and wraps it in HTML.
        $pp.process-pod($pod-tree);
        # Outputs a string that describes a html page
        $rv = $pp.source-wrap;
        # and store response so its not re-calculated
    }

    submethod TWEAK(
            :$highlight-code,
            :$type = 'rakuclosure',
            :$plugins = <simple-extras graphviz latex-render images>,
            :$def-dir
            # this option is for testing purposes
        ) {
        $!defaults = .IO.absolute.IO with $def-dir;
        $!defaults = .IO.absolute.IO with %*ENV<RAKDEFAULTS>;
        X::ProcessedPod::NoRenderPodDirectory.new(:$!defaults).throw unless $!defaults ~~ :e & :d;
        # highlight code is in parent class
        self.highlight-code = $highlight-code with $highlight-code;
        my $dir;
        # move assets if not in CWD
        for <rakudoc-styling.css favicon.ico Camelia.svg> {
            $dir = self.verify($_);
            "$dir/$_".IO.copy($_) if $dir eq $!defaults
        }
        # find templates and evaluate from there.
        $dir = self.verify("html-templates-$type.raku");
        self.templates(EVALFILE("$dir/html-templates-$type.raku"));
        # find plugin origin for each plugin
        for $plugins.comb(/\S+/) -> $p {
            $dir = self.verify($p);
            my %plugin-conf = get-config("$dir/$p");
            self.add-plugin("$dir/$p",
                :path("$dir/$p"),
                :template-raku(%plugin-conf<template-raku>:delete),
                :custom-raku(%plugin-conf<custom-raku>:delete),
                :config(%plugin-conf)
            );
        }
        # now the assets provided by the plugins must be gathered
        for <gather-css gather-js-jq> -> $p {
            my &callable = EVALFILE "$!defaults/$p/collator.raku";
            my @assets = indir( "$!defaults/$p", { &callable(self) });
            self.modify-templates(EVALFILE "$!defaults/$p/templates.raku" );
            "$!defaults/$p/$_".IO.copy($_) for @assets
        }
        #cleanup
        for <gather-css gather-js-jq> -> $p {
            my &callable = EVALFILE "$!defaults/$p/cleanup.raku";
            indir( "$!defaults/$p", { &callable() });
        }
    }

    #| verify if the path exists in either defaults or cwd, and return where
    method verify($asset --> Str) {
        return ~$*CWD  if "$*CWD/$asset".IO ~~ :e;
        return ~$.defaults if "$.defaults/$asset".IO ~~ :e;
        X::ProcessedPod::BadDefault.new(:$asset).throw
    }
}
# All of the code below is solely to pass the legacy tests.

sub get-processor {
    Pod::To::HTML2.new(:plugins(), :type<mustache> );
}

#| Backwards compatibility for legacy Pod::To::HTML module
#| function renders a pod fragment
sub node2html($pod) is export {
    my $proc = get-processor;
    # $proc.debug = $proc.verbose = True;
    $proc.render-block($pod)
}

#| Function provided by legacy Pod::To::HTML module to encapsulate a pod-tree in a file
sub pod2html($pod, *%options) is export {
    my $proc = get-processor;
    with %options<templates> {
        if  "$_/main.mustache".IO.f {
            $proc.modify-templates(%( source-wrap => "$_/main.mustache".IO.slurp))
        }
        else {
            note "$_ does not contain required templates. Using default.";
        }
    }
    $proc.no-glossary = True;
    # old HTML did not provide a glossary
    $proc.pod-file.lang = $_ with %options<lang>;
    $proc.css = $_ with %options<css-url>;
    $proc.head = $_ with %options<head>;
    $proc.render-tree($pod);
    $proc.source-wrap
}

multi sub render(IO::Path $file, |c) is export {
    my $x = load($file);
    pod2html($x)
}
multi sub render(Str $string, |c) is export {
    pod2html(load($string))
}
