use t::TestPlagger;

test_plugin_deps;
test_requires_network;

plan 'no_plan';
run_eval_expected;

__END__

=== Test slashdot
--- input config
global:
  cache:
    class: Plagger::Cache::Null
plugins:
  - module: CustomFeed::Debug
    config:
      title: serif
      entry:
        - link: http://serif.hatelabo.jp/53719d5366f4527cbf7b70197f590e330e1b5bb7/a74cb684a8bcf1c5d4a4912aa750b9ceca388c0a
  - module: Filter::EntryFullText
--- expected
ok $context->update->feeds->[0]->entries->[0]->body;
ok $context->update->feeds->[0]->entries->[0]->title;
