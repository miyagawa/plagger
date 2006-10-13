use t::TestPlagger;

test_plugin_deps('Filter::EntryFullText');
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
          link: http://slashdot.jp/article.pl?sid=06/08/18/0449254
  - module: Filter::EntryFullText
--- expected
ok $context->update->feeds->[0]->entries->[0]->summary;
like $context->update->feeds->[0]->entries->[0]->summary->data, qr!^<p>.*?</p>$!;


