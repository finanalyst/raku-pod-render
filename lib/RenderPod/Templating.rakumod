use v6.d;
use RenderPod::Exceptions;
use RenderPod::Highlighting;

#| a structure to hold the tests that distinguish between templates and engines
#| The first element is a closure that returns True if the templates are consistent with a templating
#| engine.
#| The second element is the name of the class that encapsulates the engine.
#| The array is only used after the templates have been loaded.
#| The first true test decides the Templater, so ordering the array may be important.
sub detect-from-tests(%templates) {
    my @template-tests =
            [
#                [
#                    { %templates<format-b>.isa("Str") && %templates<format-b> ~~ / '<.contents' / },
#                    "CroTemplater"
#                ],
                [
                    { %templates<format-b>.isa("Sub") },
                    "RakuClosureTemplater"
                ],
                [
                    { %templates<format-b>.isa("Str") },
                    "MustacheTemplater"
                ],

            ];
    for @template-tests {
        return .[1] if .[0]()
    }
    X::ProcessedPod::TemplateEngineMissing.throw;
}
=begin pod
=head1 Base class

The class of a template engine should have three methods
=item render ( Str $key, %params )
=item2 $key is the template to be rendered
=item2 %params is a hash of all the parameters to be used in the template
=item refresh
=item2 re-initialises the engine after the templates have been modified
=item Str
=item2 Mandatory, provides the name of the templater that is used for plugin
template Hash files. A plugin may provide templates for one or more templating
engines (see L<RenderPod|RenderPod#Plugins>).

=end pod

##| Use Cro Web templates
#class CroTemplater is export {
#    use Cro::WebApp::Template::Repository::Hash;
#    has %!sources;
#    has %!dependents;
#    submethod BUILD(:%tmpl) {
#        templates-from-hash(%tmpl);
#        self.update-ancestors(%tmpl);
#    }
#    method update-ancestors(%templates) {
#        for %templates.kv -> $k, $v {
#            if $v ~~ / [ '<:use' \s+ \' ~ \' $<used> = .+? \s* '>' .+? ]+ $ / {
#                %!sources{$k} = $v;
#                %!dependents{$_} = $k for $/<used>
#            }
#        }
#    }
#    method render(Str $key, %params --> Str) {
#        return %params<contents> if $key eq 'raw';
#        render-template($key, %params, :hash)
#    }
#    method refresh(%new-templates) {
#        for %new-templates.keys {
#            with %!dependents{$_} {
#                %new-templates{$_} = %!sources{$_}
#                    unless %new-templates{$_}:exists
#            }
#        }
#        modify-template-hash(%new-templates);
#        self.update-ancestors(%new-templates);
#    }
#    method Str {
#        "CroTemplater"
#    }
#    method make-template-from-string(%strings --> Hash) {
#        my %templates;
#        for %strings.kv -> $key, $str {
#            %templates{$key} = qq:to/TMPL/
#            <:sub $key>
#            $str\</:>
#            TMPL
#        }
#        %templates
#    }
#}

#| The templates are sub (%prm, %tml) that act on the keys of %prm and return a Str
#| keys 'escaped' and 'raw' take a Str as the only argument
class RakuClosureTemplater is export {
    has %!tmpl;
    submethod BUILD(:%!tmpl) {}
    #| maps the key to template and emits the result of the closure
    method render(Str $key, %params --> Str) {
        # 'raw' typically does not need any extra processing. If it does, the following line can be commented out.
        return %params<contents> if $key eq 'raw';
        #special case escape key. The template only expects a String scalar.
        #other templates expect two %
        if $key eq 'escaped' {
            %!tmpl<escaped>(%params<contents>)
        }
        else
        {
            %!tmpl{$key}(%params, %!tmpl)
        }
    }
    method refresh(%new-templates) {
        { %!tmpl{$^a} = $^b } for %new-templates.kv;
    }
    # no op for RakuClosure
    method Str {
        "RakuClosureTemplater"
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

class MustacheTemplater is export {
    # mustache acts on each template as it is given, and caches used ones.
    require Template::Mustache;
    # templating parameters. }}}
    has $!engine;
    has %!tmpl;
    submethod BUILD(:%!tmpl) {}

    method refresh(%new-templates) {
        { %!tmpl{$^a} = $^b } for %new-templates.kv;
        $!engine = Nil;
    }
    # templating engines like mustache do not handle logic or loops, which some Pod formats require.
    # hence we pass a Subroutine instead of a string in the template
    # the subroutine takes the same parameters as rendition and produces a mustache string
    # eg P format template escapes containers

    #| maps the key to template and renders the bloc
    method render(Str $key, %params --> Str) {
        $!engine = Template::Mustache.new without $!engine;
        my $interpolate = %!tmpl{$key} ~~ Block
                ?? %!tmpl{$key}(%params)
                # if the template is a block, then run as sub and pass in the params
                !! %!tmpl{$key};
        $!engine.render(
                $interpolate,
                %params, :from(%!tmpl)
                )
    }
    method Str {
        "MustacheTemplater"
    }
    method make-template-from-string(%strings --> Hash) {
        %strings
    }
}

role SetupTemplates does Highlighting {
    #| the following are required to render pod. Extra templates, such as head-block and header can be added by a subclass
    has @.required = < block-code comment declarator defn dlist-end dlist-start escaped footnotes format-b format-c
        format-i format-k format-l format-n format-p format-r format-t format-u format-x glossary heading
        item list meta unknown-name output para pod raw source-wrap table toc >;
    #| must have templates. Generically, no templates loaded.
    has Bool $.templates-loaded is rw = False;
    #| the object containing the templater engine
    has $.templater is rw;
    #| storage of loaded templates
    has %.tmpl;
    #| a variable to collect which templates have been used for trace and debugging
    has BagHash $.templs-used is rw .= new;
    #| allows for templates to be replaced during pod processing
    #| repeatedly generating the template engine is expensive
    #| $templates may be either a Hash of templates, or
    #| a Str path to a Raku program that evaluates to a Hash
    #| Keys of the hash are added to the Templates, silently over-riding
    #| previous keys.
    method modify-templates($templates, :$path = '.', :$plugin = False)
    {
        # no action for blank string or empty Hash
        return unless $templates;
        my %new-templates;
        given $templates {
            when Associative { %new-templates = $templates }
            when Str {
                %new-templates = indir($path, { EVALFILE $templates });
            }
        }
        # if the templates are from a plugin, there may be a set of templates
        # for the templater engine chosen. If not throw an error.
        # The templater key may have variable capitalisation eg RakuClo.., or rakuclo... etc
        if $plugin {
            my $template-type = $.templater.Str.lc;
            my $got-ts = False;
            if 'rakuclosuretemplater' (elem) %new-templates.keys>>.lc {
                for %new-templates.keys {
                    next unless $template-type eq .lc;
                    %new-templates = %new-templates{ $_ };
                    $got-ts = True;
                    last
                }
            }
            elsif $template-type eq 'rakuclosuretemplater' {
                $got-ts = True;
                # new-templates can stay unchanged
            }
            X::ProcessedPod::BadPluginTemplates.new(:$path, :$template-type).throw
                unless $got-ts
        }
        { %.tmpl{$^a} = $^b } for %new-templates.kv;
        $!templater.refresh(%new-templates)
    }
    #| accepts a string filename that must evaluate to a hash
    #| or a hash of templates
    #| the keys must be a superset of the required templates
    multi method templates($templates, :$path = '.') {
        given $templates {
            when Hash { %.tmpl = $templates }
            when Str {
                # a string should be a filename with a compilable file
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
        # add name to Bag
        $!templater.render($key, %params)
    }
    #| Detects which template engine is to be used with the templates provided
    #| First looks for the key '_templater', which if it exists, should contain the templater class name
    #| Second tries to run the autodetect test, first test returning True defines the templater
    method set-engine {
        with %!tmpl<_templater> {
            try {
                $!templater  = ::(%!tmpl<_templater>).new(:%!tmpl);
                CATCH {
                    X::ProcessedPod::UnknownTemplatingEngine
                        .new(:attempted(%!tmpl<_templater>))
                        .throw
                }
            }
        }
        else {
            $!templater = ::(detect-from-tests(%!tmpl)).new(:%!tmpl)
        }
        X::ProcessedPod::NoTemplateEngine.new.throw
            unless $!templater;
        note "Using $!templater" if $.verbose;
    }
    method reset-used {
        $!templs-used .= new
    }
}
