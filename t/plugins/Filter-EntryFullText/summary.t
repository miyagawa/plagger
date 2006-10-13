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
      title: slashdot
      entry:
        - title: Slashdot.jp
          link: http://slashdot.jp/article.pl?sid=06/08/14/1941259
          body: This is summary set in description.
  - module: Filter::EntryFullText
--- expected
is $context->update->feeds->[0]->entries->[0]->summary, "This is summary set in description.";


