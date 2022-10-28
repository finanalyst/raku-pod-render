module Test-Templates {
    use Test;
    use ProcessedPod;
    use RenderPod::Templating;

    our %struct = %(
        escaped => %( :contents('Str') ),
        raw => %( :contents('Str') ),
        block-code => %( :contents('Str') ),
        comment => %( :contents('Str') ),
        declarator => %( :target('Str'), :code('Str'), :contents('Str') ),
        dlist-start => 'Str',
        defn => %( :term('Str'), :contents('Str') ),
        dlist-end => 'Str',
        format-b => %( :contents('Str') ),
        format-c => %( :contents('Str') ),
        format-i => %( :contents('Str') ),
        format-k => %( :contents('Str') ),
        format-r => %( :contents('Str') ),
        format-t => %( :contents('Str') ),
        format-u => %( :contents('Str') ),
        para => %( :contents('Str') ),
        format-l => %(
            :internal('Bool'),
            :external('Bool'),
            :target('Str'),
            :local('Bool'),
            :link-label('Str'),
            :place('Str')
        ),
        format-n => %(
            :retTarget('Str'),
            :fnTarget('Str'),
            :fnNumber('Str')
        ),
        format-p => %(
            :contents('Str'),
            :html('Bool')
        ),
        format-x => %(
            :target('Str'),
            :text('Str'),
            :header('Bool')
        ),
        heading => %(
            :level('Str'),
            :target('Str'),
            :top('Str'),
            :text('Str')
        ),
        item => %( :contents('Str')),
        list => %( :items( @('Str', ) ) ),
        unknown-name => %(
            :level('Str'),
            :target('Str'),
            :top('Str'),
            :name('Str'),
            :contents('Str')
        ),
        output => %( :contents('Str') ),
        pod => %(
            :name('Str'),
            :contents('Str'),
            :tail('Str')
        ),
        table => %(
            :caption('Str'),
            :headers( @( %(
                :cells( @('Str', ) )
            ) ),
            ),
            :rows( @( %(
                :cells( @('Str', ) )
            ) ),
            )
        ),
        source-wrap => %(
            :name('Str'),
            :title('Str'),
            :subtitle('Str'),
            :title-target('Str'),
            :metadata('Str'),
            :lang('Str'),
            :toc('Str'),
            :glossary('Str'),
            :body('Str'),
            :footnotes('Str'),
            :renderedtime('Str'),
            :path('Str')
        ),
        footnotes => %(
            :notes( [ {
                          :fnTarget('Str'),
                          :text('Str'),
                          :retTarget('Str'),
                          :fnNumber('Str')
                      }, ]
            )
        ),
        glossary => %(
            :glossary( @( %(
                              :text('Str'),
                              :refs( @( %(
                                            :target('Str'),
                                            :place('Str')
                                        ), )
                              )
                          ), ) )
        ),
        toc => %(
            :toc( @( %(
                         :level('Str'),
                         :target('Str'),
                         :text('Str')
                     ), ) )
        ),
        meta => %(
            :meta( @( %(
                          :name('Str'),
                          :value('Str')
                      ), ) )
        ),
    );

    my class Rendering does SetupTemplates {
        has $.debug is rw;
        has $.verbose is rw;
    };

    #|Short for 'are all minimum templates present in the hash'. Takes a hash, whose keys are template names.
    #| Checks the key-names contains all of the required templates.
    multi sub templates-present( %templates, Str $description = 'minimum templates present' ) is export {
        my $required = SetupTemplates.new.required.Set;
        my $got = %templates.keys.Set;
        ok ($required (<) $got), $description;
        diag ("Template(s) required, but not supplied: { ($required (-) $got).keys.join(', ') }")
            unless ($required (<) $got);
    }

    #|Checks whether the required templates render all parameters. Fails if any parameters are not rendered.
    #| If a parameter should not appear, render it as a comment or invisible element, so that it is in the output for
    #| it to match the specification, but not be seen when finally rendered. If there are more templates in the hash
    #| than are in the specifications, they are ignored.
    multi sub templates-match( %templates, Str $desc = 'minimum templates match the specification' ) is export {
        my $render = Rendering.new(:!debug);
        $render.templates(%templates);
        my %rv = match-renderer-to-spec( $render, :%struct );
        ok ! %rv<warn>.elems.so, $desc;
        diag ("Templates with errors: " ~ %rv<warn>.keys.join(', ')) if %rv<warn>.keys.elems
    }

    #|Check that templates in %templates match the specifications in %specifications. True if the templates match,
    #| AND all the templates in %templates are specified in %specifications.
    multi sub extra-templates-match( %templates, %specifications, Str $desc is copy = 'extra templates match') is export {
        my $render = Rendering.new(:!debug);
        $render.templates(%templates);
        my %rv = match-renderer-to-spec( $render, :struct(%specifications) );
        $desc ~= ("\n#Templates with errors: " ~ %rv<warn>.keys.join(', ')) if %rv<warn>.elems;
        ok ! %rv<warn>.elems.so, $desc
    }

    #| $template file to be tested
    #| :$extra specification file for extra templates
    #| :verbosity = 0 return 0, or list templates with errors
    #| = 1 0 + parameters sent, sub-keys not returned
    #| = 2 1 + sub-keys found in error templates
    #| = 3 2 + full response for error templates
    #| = 4 all templates with sub-key returns
    #| = 5 5 + full response for all templates
    sub test-templates($template-file, Str :$extra, Int :$verbosity = 0 ) is export {
        my Rendering $tt .= new(:!debug);
        $tt.templates($template-file);
        # remove _template key if it exists from templates
        $tt.tmpl<_templater>:delete with $tt.tmpl<_templater>;
        # verify %struct and ProcessedPod are still in sync
        my $required = Set.new( $tt.required);
        my $got = Set.new( %struct.keys );
        die "Panic. Contact maintainer. Required templates in ProcessedPod and here are out of sync.\n"
                ~( "Template(s) required, but not in test-templates: { ($required (-) $got).keys.join(', ') }")
            if ($required (>) $got);
        my @extra;
        with $extra {
            if $extra.IO.f {
                my %extra = EVALFILE $extra;
                %struct ,= %extra;
                @extra = %extra.keys
            }
            else {
                note $extra ~ q:to/MSG/
                    was given for extra template tests, but does not exist as a file.
                    Only testing required templates.
                MSG
            }
        }
        my %rets = match-renderer-to-spec( $tt, :%struct );
        my $extra-keys = $tt.tmpl.keys (-) %struct.keys;
        say "Template test. Aggregate results:";
        say "\tNo of templates required: { +$tt.required }";
        say "\tNo of templates specified externally: { +@extra }",
                +@extra ?? ", viz.\n\t\t<{ @extra.sort.join('>, <') }>" !! '';
        say "\tNo of templates without specifications: { $extra-keys.elems }",
                $extra-keys.elems ?? ", viz.\n\t\t<{ $extra-keys.keys.sort.join('>, <')}>"
                !! '';
        #  :verbosity = 0 only list templates with errors
        #  = 1 0 + parameters sent, sub-keys not returned
        #  = 2 1 + sub-keys found in error templates
        #  = 3 2 + full response for error templates
        #  = 4 all templates with sub-key returns
        #  = 5 5 + full response for all templates
        say "\tKeys with warnings: {+%rets<warn>.keys}"
                ~ ((+%rets<warn>.keys and ! $verbosity)
                        ?? ", viz.{ %rets<warn>.kv.map({ "\n\t\t$^a: " ~ $^b.join(', ') }) }"
                        !! "\n");
        for %rets<warn>.keys.sort -> $key {
            if $verbosity {
                say "For ｢$key｣";
                say %rets<report>{$key}[0];
                say("\t$_") for %rets<warn>{$key}.list;
                if $verbosity > 1 { say "\t{ %rets<report>{$key}[1 .. *-1].join("\n\t")}\n" }
                if $verbosity > 2 { say "Full response for ｢$key｣ was: \n %rets<verbose>{$key}" }
            }
        }
        if $verbosity > 3 {
            say "\nPassing templates\n";
            for %rets<report>.keys.sort.grep( { $_ ~~ none( %rets<warn>.keys ) } ) -> $key {
                next unless $key;
                say "For ｢$key｣";
                say %rets<report>{$key}[0];
                say "\t{ %rets<report>{$key}[1 .. *-1].join("\n\t")}\n";
                if $verbosity > 4 {
                    say "Full response for ｢$key｣ was: \n %rets<verbose>{$key}"
                }
            }
        }
    }

    multi sub match-renderer-to-spec( Rendering $tt, :%struct --> Hash ) {
        my $rv;
        my %warn;
        my %report;
        my %verbose;
        my %test;
        for %struct.sort -> (:key($key), :value($defn)) {
            if $defn ~~ Str and $defn eq 'Str' {
                try {
                    $rv = $tt.rendition($key, %())
                }
                if $! { %warn{$key} = $!.message.subst(/\v+/,"\n\t\t" ) }
                elsif $rv ~~ Str {
                    %report{$key}.append: 'Expected response'
                }
                else {
                    %warn{$key}.append: 'Str expected, got ' ~ $rv.raku
                }
            }
            elsif $defn !~~ Associative {
                note "The definition for $key must be either Str or Associative, skipping";
                %warn{$key}.append: 'Test definition invalid';
            }
            else { # either Str or Hash at this level
                %test = make-test( $defn );
                my @expected = (%test<_EXPECTED>:delete).flat;
                $rv = $tt.rendition($key, %test);
                %report{$key}.append: "parameters sent: ｢{%test.raku}｣";
                %verbose{$key} = $rv;
                for @expected -> $sub-key {
                    my $key-name = $sub-key.subst(/ ^ .+ '_' /, '');
                    if $rv ~~ / $sub-key / {
                        %report{$key}.append: "ok ｢$key-name｣ present"
                    }
                    else {
                        %warn{$key}.append: "｢$key-name｣ absent";
                    }
                }
            }
            CATCH {
                default { %warn{$key} ~= .message.subst(/\v+/,"\n\t\t   ", :g) ~ "\n\t\t\tTested with: { %test.raku }" }
            }
            CONTROL {
                default { %warn{$key} ~= .message.subst(/\v+/,"\n\t\t   ", :g) ~ "\n\t\t\tTested with: { %test.raku }" }
            }
        }
        %(:%report, :%warn, :%verbose)
    }

    multi sub make-test( %tmps --> Associative ) {
        my %test;
        my @expected;
        for %tmps.kv -> $key, $defn {
            if $defn ~~ Str and $defn eq 'Str' {
                @expected.push( %test{$key} = ([~] ('a'..'z').roll(5)) ~ "_$key" );
            }
            elsif $defn ~~ Str and $defn eq 'Bool' {
                %test{$key} = (True,False).pick # No way to predict result from template
            }
            elsif $defn ~~ Associative {
                %test{$key} = make-test( $defn );
                @expected.append( (%test{$key}<_EXPECTED>:delete).flat );
            }
            else { # is Positional
                my %rv = make-test( $defn );
                %test{$key} = %rv<_ARRAY>;
                @expected.append( %rv<_EXPECTED>.flat );
            }
        }
        %test<_EXPECTED> =  @expected;
        %test
    }

    multi sub make-test( @tmps --> Associative ) {
        my %test;
        if @tmps[0] eq 'Str' {
            %test<_ARRAY> = [ ( %test<_EXPECTED> =  [~] ('a'..'z').roll(5) ), ];
        }
        else { # is Positional or Associative
            my %rv = make-test( @tmps[0] );
            %test<_EXPECTED> = ( %rv<_EXPECTED>:delete ).flat;
            if %rv<_ARRAY>:exists {
                %test<_ARRAY> = %rv<_ARRAY>
            }
            else {
                %test<_ARRAY> = [ %rv, ]
            }
        }
        %test
    }

}
