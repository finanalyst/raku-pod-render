use v6.d;
use RenderPod::Exceptions;
use RenderPod::Highlighting;

=begin pod
=head1 Base class

The class of a template engine should have three methods
=item render ( %tmpl, Str $key, %params )
=item2 %tmpl is a hash containing all the required templates
=item2 $key is the template to be rendered
=item2 %params is a hash of all the parameters to be used in the template
=item restart
=item2 re-initialises the engine after the templates have been modified
=item Str
=item2 Not strictly needed, but provides a String when a template class is printed.

=end pod

role Auto-detect-templater {
    #| storage of loaded templates
    has %.tmpl is rw;
    #| a structure to hold the tests that distinguish between templates and engines
    #| The first element is a closure that returns True if the templates are consistent with a templating
    #| engine.
    #| The second element is the name of the class that encapsulates the engine.
    #| The array is only used after the templates have been loaded.
    #| The first true test decides the Templater, so ordering the array may be important.
    has @!tmp-config =
            [
                [
                    { %!tmpl<format-b>.isa("Sub") },
                    "RakuClosureTemplater"
                ],
                [
                    { %!tmpl<format-b>.isa("Str") },
                    "MustacheTemplater"
                ],

            ];
    method detect-templater {
        for @!tmp-config {
            # The 0-th element of the array contains the test
            next unless .[0]();
            # the 1-st element contains the class to be instantiated
            return ::(.[1]).new;
        }
        X::ProcessedPod::TemplateEngineMissing.throw;
    }
}

#| Use Cro Web templates
class CroTemplater is export {
    method render(%tmpl, Str $key, %params --> Str) {

    }
    method restart {

    }
    method Str {
        "Cro Web template engine"
    }
    method make-template-from-string(%strings --> Hash) {
        %strings
    }
}

#| The templates are sub (%prm, %tml) that act on the keys of %prm and return a Str
#| keys 'escaped' and 'raw' take a Str as the only argument
class RakuClosureTemplater is export {
    #| maps the key to template and emits the result of the closure
    method render(%tmpl, Str $key, %params --> Str) {
        # 'raw' typically does not need any extra processing. If it does, the following line can be commented out.
        return %params<contents> if $key eq 'raw';
        X::ProcessedPod::Non-Existent-Template.new(:$key, :%params).throw
        unless %tmpl{$key}:exists;
        #special case escape key. The template only expects a String scalar.
        #other templates expect two %
        if $key eq 'escaped' {
            %tmpl<escaped>(%params<contents>)
        }
        else
        {
            %tmpl{$key}(%params, %tmpl)
        }
    }
    method restart {}
    # no op for RakuClosure
    method Str {
        "Raku Closure template engine"
    }
    method make-template-from-string(%strings --> Hash) {
        my %templates;
        for %strings.kv -> $key, $str {
            %templates{$key} = sub (%prm, %tml? --> Str) {
                $str
            }
        }
        %templates
    }
}

#| A helper class for RakuClosureTemplates
sub gen-closure-template (Str $tag) is export {
    my $start = '<' ~ $tag ~ '>';
    my $end = '</' ~ $tag ~ '>';
    return sub (%prm, %tml? --> Str) {
        $start ~ (%prm<contents> // '') ~ $end;
    }
}

class MustacheTemplater is export {
    require Template::Mustache;
    # templating parameters.
    has $!engine;
    method restart {
        $!engine = Nil;
    }
    # templating engines like mustache do not handle logic or loops, which some Pod formats require.
    # hence we pass a Subroutine instead of a string in the template
    # the subroutine takes the same parameters as rendition and produces a mustache string
    # eg P format template escapes containers

    #| maps the key to template and renders the bloc
    method render(%tmpl, Str $key, %params --> Str) {
        $!engine = Template::Mustache.new without $!engine;
        my $interpolate = %tmpl{$key} ~~ Block
                ?? %tmpl{$key}(%params)
                # if the template is a block, then run as sub and pass in the params
                !! %tmpl{$key};
        $!engine.render(
                $interpolate,
                %params, :from(%tmpl)
                )
    }
    method Str {
        "Mustache template engine"
    }
    method make-template-from-string(%strings --> Hash) {
        %strings
    }
}

role SetupTemplates does Auto-detect-templater does Highlighting {
    #| the following are required to render pod. Extra templates, such as head-block and header can be added by a subclass
    has @.required = < block-code comment declarator defn dlist-end dlist-start escaped footnotes format-b format-c
        format-i format-k format-l format-n format-p format-r format-t format-u format-x glossary heading
        item list meta named output para pod raw source-wrap table toc >;
    #| must have templates. Generically, no templates loaded.
    has Bool $.templates-loaded is rw = False;
    #| the object containing the templater engine
    has $.templater is rw;
    #| a variable to collect which templates have been used for trace and debugging
    has BagHash $.templs-used is rw .= new;
    #| allows for templates to be replaced during pod processing
    #| repeatedly generating the template engine is expensive
    #| $templates may be either a Hash of templates, or
    #| a Str path to a Raku program that evaluates to a Hash
    #| Keys of the hash are added to the Templates, silently over-riding
    #| previous keys.
    method modify-templates($templates, :$path = '.')
    {
        return unless $templates;
        # no action for blank string or empty Hash
        my %new-templates;
        given $templates {
            when Hash { %new-templates = $templates }
            when Str {
                #use SEE_NO_EVAL;
                %new-templates = indir($path, { EVALFILE $templates });
            }
        }
        { %.tmpl{$^a} = $^b } for %new-templates.kv;
        $!templater.restart
    }
    #| accepts a string filename that must evaluate to a hash
    #| or a hash of templates
    #| the keys must be a superset of the required templates
    multi method templates($templates, :$path = '.') {
        given $templates {
            when Hash { %.tmpl = $templates }
            when Str {
                # a string should be a filename with a compilable file
                #use SEE_NO_EVAL;
                try {
                    %.tmpl = indir($path, { EVALFILE $templates });
                    CATCH {
                        default {
                            X::ProcessedPod::TemplateFailure.new(:error(.message)).throw
                        }
                    }
                }
            }
        }

        X::ProcessedPod::MissingTemplates.new(:missing((@.required (-) %.tmpl.keys).keys.flat)).throw
        unless %.tmpl.keys (>=) @.required;
        # the keys on the RHS above are required in %.tmpl. To throw here, the templates supplied are not
        # a superset of the required keys.
        $.templates-loaded = True;
        self.set-engine
    }
    #| rendition takes a key and parameters and calls the template for the key
    method rendition(Str $key, %params --> Str) {
        X::ProcessedPod::MissingTemplates.new.throw unless $.templates-loaded;
        return '' if $key eq 'zero';
        # special case this as there must be no EOL.
        X::ProcessedPod::Non-Existent-Template.new(:$key, :%params).throw
        unless %.tmpl{$key}:exists;
        if $key eq 'block-code' and $.highlight-code {
            %params<highlighted> = self.insert-highlights.(%params<contents>)
        }

        note "At $?LINE rendering with \<$key>" if $.debug;

        $.templs-used{$key}++;
        # add name to Set
        $!templater.render(%.tmpl, $key, %params)
    }
    #| tests the loaded templates and autodetects the templater
    method set-engine {
        $!templater = self.detect-templater;
        X::ProcessedPod::NoTemplateEngine.new.throw
        unless $!templater;
        note "Using $!templater" if $.verbose;
    }
    method reset-used {
        $!templs-used .= new
    }
}
