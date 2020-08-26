#!/usr/bin/env perl6
use ProcessedPod;

my %struct = %(
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
        :local('Str'),
        :contents('Str')
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
    named => %(
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
            :counter('Str'),
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

my class Rendering does RakuClosureTemplater {
    has $.debug is rw;
    has $.verbose is rw;
};

sub MAIN($template-file, Str :$extra, Bool :$debug = False, Bool :$verbose = False ) {
    my Rendering $tt .= new(:$debug, :$verbose);
    $tt.templates($template-file);
    my @extra;
    my $vc = 0;
    if $extra.IO.f {
        my %extra = EVALFILE $extra;
        %struct ,= %extra;
        @extra = %extra.keys
    }
    else {
        note $extra ~ q:to/MSG/ with $extra
                was given for extra template tests, but does not exist as a file.
                Only testing required templates.
            MSG
    }
    my $rv;
    my %warn;
    my %test;
    for %struct.sort -> (:key($key), :value($defn)) {
        if $defn ~~ Str and $defn eq 'Str' {
            try {
                $rv = $tt.rendition($key, %())
            }
            %warn{$key} = $!.message if $!;
            %warn{$key} ~= 'Str expected, got ' ~ $rv.raku
                unless $rv ~~ Str
        }
        elsif $defn !~~ Associative {
            note "The definition for $key must be either Str or Associative, skipping";
            %warn{$key} = 'Test definition invalid';
        }
        else { # either Str or Hash at this level
            %test = make-test( $defn );
            my @expected = (%test<_EXPECTED>:delete).flat;
            $rv = $tt.rendition($key, %test);
            %warn{$key} ~= "Expected: {%test<_EXPECTED>}\nGot: $rv"
                unless $rv ~~ / @expected /
        }
        CATCH {
            default { %warn{$key} ~= .message ~ "\n\t\t\tTested with: { %test.raku }" }
        }
        CONTROL {
            default { %warn{$key} ~= .message ~ "\n\t\t\tTested with: { %test.raku }" }
        }
        LEAVE {
            if $verbose {
                $vc++;
                say "ok $vc - ｢$key｣ passed test" unless %warn{$key}:exists;
                say "nok $vc - ｢$key｣ failed test: ", %warn{$key} if %warn{$key}:exists;
            }
        }
    }
    my $extra-keys = $tt.tmpl.keys (-) $tt.required;
    say "Template test. Aggregate results:";
    say "\tNo of templates required: { +$tt.required }";
    say "\tNo of extra templates provided: { +@extra }",
            +@extra ?? ", viz.\n\t\t<{ @extra.sort.join('>, <') }>" !! '';
    say "\tNo of templates supplied, not required: { $extra-keys.elems }",
            $extra-keys.elems ?? ", viz.\n\t\t<{ $extra-keys.keys.sort.join('>, <')}>"
            !! '';
    say "\tKeys with warnings: {+%warn.keys}",
            +%warn.keys ?? ", viz.\n{ %warn.fmt("\t\t%s: %s")}" !! '';
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
    my @expected;
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