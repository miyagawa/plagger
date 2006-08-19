use strict;
use t::TestPlagger;

test_plugin_deps;
plan 'no_plan';
run_eval_expected;

__END__

=== Loading Filter::AtomLinkRelated
--- input config
plugins:
  - module: Filter::AtomLinkRelated
--- expected
ok 1, $block->name;

=== Use link rel="related" as entry link
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/atom-related.xml
  - module: Filter::AtomLinkRelated
--- expected
is $context->update->feeds->[0]->entries->[0]->link, 'http://xcezx.net/blog/development/plagger-plugin-publish-mixidiary.html';

