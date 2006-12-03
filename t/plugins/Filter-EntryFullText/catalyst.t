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
      title: foo
      entry:
        - link: http://www.catalystframework.org/calendar/2006/2
  - module: Filter::EntryFullText
--- expected
ok $context->update->feeds->[0]->entries->[0]->body;
ok $context->update->feeds->[0]->entries->[0]->title;
isnt $context->update->feeds->[0]->entries->[0]->title, 'foo';
