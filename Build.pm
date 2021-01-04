use v6;

unit class Build;
sub set-highlight-basedir( --> Str ) {
    my $basedir = $*HOME;
    my $hilite-path = "$basedir/.local/lib".IO.d
            ?? "$basedir/.local/lib/raku-pod-render/highlights".IO.mkdir
            !! "$basedir/.raku-pod-render/highlights".IO.mkdir;
    exit 1 unless ~$hilite-path;
    ~$hilite-path
}
sub test-highlighter( Str $hilite-path --> Bool ) {
    ?( "$hilite-path/package-lock.json".IO.f and "$hilite-path/atom-language-perl6".IO.d )
}

method build($dist-path) {
    if %*ENV<POD_RENDER_NO_HIGHLIGHTER>:exists and %*ENV<POD_RENDER_NO_HIGHLIGHTER> {
        note "Not setting up highlighting";
        exit 0
    }
    # detect the presence of npm
    my $npm-run = run 'npm', '-v', :out;
    my $npm-return = $npm-run.out.get;
    if $npm-return {
        my $node-run = run 'node', '-v', :out;
        my $node-v = ~$node-run.out.slurp(:close).comb(/ \d+ /)[0];
        note "Using npm version $npm-return and node $node-v." ~ ( $node-v <  14 ?? "Problems may occur for node < 14" !! '');
    }
    else {
        note "'npm' was not detected using 'npm -v'. 'npm' is needed to set up the highlighting stack.";
        exit 1
    }
    my $hilite-path = set-highlight-basedir;
    if test-highlighter( $hilite-path ) {
        unless %*ENV<POD_RENDER_FORCE_HIGHLIGHTER_REFRESH> {
            # it already exists, and refresh is not forced
            note "Highlighter already exists at $hilite-path.\nSet env POD_RENDER_FORCE_HIGHLIGHTER_REFRESH to reinstall";
            exit 0
        }
    }
    note "Trying to create highlighter at $hilite-path";
    chdir $hilite-path;
    for <highlight-filename-from-stdin.coffee package.json> -> $fn {
        "$hilite-path/$fn".IO.spurt:
        "$dist-path/resources/highlights/$fn".IO.slurp;
    }
    my $git-run;
    if 'atom-language-perl6'.IO.d {
        chdir 'atom-language-perl6';
        $git-run = run 'git', 'pull', '-q', :err;
    }
    else {
        $git-run = run 'git', 'clone', 'https://github.com/perl6/atom-language-perl6','atom-language-perl6', '-q', :err
    }
    my $git-run-err = $git-run.err.get;
    note $git-run-err if $git-run-err;
    my $npm-install = run 'npm', 'i', '.',:err,:out;
}
