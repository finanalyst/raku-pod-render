use Test;
use RenderPod::Test-Templates;
plan 3;

diag "Two failures are planned, test 2 - errors in return values, test 4 - incomplete list";
my %templates = EVALFILE 'resources/html-rakuclosure.raku';
templates-present %templates, 'Yes they are all there';
my %extra = EVALFILE 'resources/extra-test.raku';
extra-templates-match %templates, %extra, 'We got em';
todo 1;
subtest 'Expected failures' => {
    templates-match %templates;
    %templates<toc>:delete;
    templates-present %templates, 'test caught the absence of toc';
}

done-testing;
