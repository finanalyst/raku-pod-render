# Generic Renderer for POD files

Currently this project is still under development.

It relies heavily on Template::Mustache. The cannonical version is not cached. I have PR with a cached version.
Without caching, a large Pod file takes several seconds to render.

The version of Template::Mustache under finanalyst is a cached version.

Assuming the auth: "github:finanalyt" version is cloned to p6-Template-Mustache, then the following will work

```
prove -vre 'raku -Ilib -I../p6-Template-Mustache'
```

For more information look at the Pod in `lib/Pod/To/HTML`


