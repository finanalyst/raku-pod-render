use Test;

plan 2;

use-ok "ProcessedPod";

constant AUTHOR = ?%*ENV<AUTHOR_TESTING>;

if AUTHOR {
    require Test::META <&meta-ok>;
    meta-ok;
}
else {
    skip-rest "Skipping author test";
}

done-testing;
