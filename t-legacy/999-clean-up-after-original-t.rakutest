use Test;

plan 1;
for <class test multi> { ( "t/$_.pod6").IO.unlink }
'html-templates.raku'.IO.unlink;
't/templates/main.mustache'.IO.unlink;
't/templates'.IO.rmdir if 't/templates'.IO.d;

ok 1, 'clean up t/ directory';

done-testing;
