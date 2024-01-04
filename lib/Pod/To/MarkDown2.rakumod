use ProcessedPod;
use RenderPod::Exceptions;
use JSON::Fast;

unit class Pod::To::MarkDown2 is ProcessedPod;
has $.def-ext is rw;
has $.defaults = "$*HOME/.local/share/PodRender".IO;
has Bool $.github-badge is rw = False;

submethod TWEAK( :$def-dir, :$type = 'mustache' ) {
    $!defaults = .IO.absolute.IO with $def-dir;
    X::ProcessedPod::NoRenderPodDirectory.new(:$!defaults).throw unless $!defaults ~~ :e & :d;
    $!def-ext = 'md';
    # find templates and evaluate from there.
    my $dir = self.verify("md-templates-$type.raku");
    self.templates(EVALFILE("$dir/md-templates-$type.raku"));
    if $!github-badge {
        X::ProcessedPod::MarkDown::BadgeError.new.throw
            unless 'META6.json'.IO.f;
        my $def-badge-path;
        if '.github/workflows/'.IO.d {
            $def-badge-path = '.github/workflows'.IO.dir[0].basename
        }
        else {
            note 'there is no .github/workflows file, so badge will not work';
            $def-badge-path = 'dummy.yaml'
        }
        $def-badge-path = "/actions/workflows/$def-badge-path/badge.svg";
        use JSON::Fast;
        my $path = from-json('META6.json'.IO.slurp)<source-url>
                .subst(/ ^ .+ <?before \/\/ > /, 'https:')
                .IO.extension('');
        $path ~= $def-badge-path;
        self.modify-templates(self.templater.make-template-from-string(
                %(:github_badge("![github-tests-passing-badge]($path)\{\{> nl }}"),)
                ))
    }
}
method rewrite-target(Str $candidate-name is copy, :$unique --> Str) {
    # when indexing a unique target is needed even when same entry is repeated
    # when a Heading is a target, the reference must come from the name
    # the following algorithm for target names comes from github markup
    # https://gist.github.com/asabaylus/3071099#gistcomment-2563127
    #        function GithubId(val) {
    #	return val.toLowerCase().replace(/ /g,'-')
    #		// single chars that are removed
    #		.replace(/[`~!@#$%^&*()+=<>?,./:;"'|{}\[\]\\–—]/g, '')
    #		// CJK punctuations that are removed
    #		.replace(/[　。？！，、；：“”【】（）〔〕［］﹃﹄“”‘’﹁﹂—…－～《》〈〉「」]/g, '')
    #}
    $candidate-name = $candidate-name.lc
            .subst(/\s+/, '-', :g)
            .subst(/<[`~!@#$%^&*()+=<>,./:;"'|{}\[\]\\–—]>/, '', :g)
            .subst(/<[。！，、；：“【】（）〔〕［］﹃﹄”’﹁﹂—…－～《》〈〉「」]> /, '', :g);
    if $unique {
        $candidate-name ~= '-0' if $candidate-name (<) $.pod-file.targets;
        ++$candidate-name while $.pod-file.targets{$candidate-name};
        # will continue to loop until a unique name is found
    }
    $.pod-file.targets{$candidate-name}++;
    # now add to targets, no effect if not unique
    $candidate-name
}

method render($pod-tree, :$def-dir) {
    state $rv;
    return $rv with $rv;
    # Some implementations of raku/perl6 called the classes render method twice,
    # so it's necessary to prevent the same work being done repeatedly

    my $pp = self.new(:name($*PROGRAM-NAME), :no-glossary, :$def-dir);
    $pp.process-pod($pod-tree);
    # Outputs the string with a top, tail, TOC and Glossary
    $rv = $pp.source-wrap;
}

#| verify if the path exists in either defaults or cwd, and return where
method verify($asset --> Str) {
    return ~$*CWD  if "$*CWD/$asset".IO ~~ :e;
    return ~$.defaults if "$.defaults/$asset".IO ~~ :e;
    X::ProcessedPod::BadDefault.new(:$asset).throw
}