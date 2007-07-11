use t::TestPlagger;

test_plugin_deps;
test_requires_network;

plan 'no_plan';
run_eval_expected;

__END__

=== Test photon
--- input config
global:
  cache:
    class: Plagger::Cache::Null
plugins:
  - module: CustomFeed::Debug
    config:
      entry:
        - link: http://members.mh-frontier.jp/information/?id=0335
  - module: Filter::EntryFullText
--- expected
ok $context->update->feeds->[0]->entries->[0]->body;
ok $context->update->feeds->[0]->entries->[0]->title;

