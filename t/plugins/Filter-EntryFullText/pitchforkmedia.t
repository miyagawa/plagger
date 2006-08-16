use t::TestPlagger;

test_plugin_deps;
test_requires 'HTML::TreeBuilder::XPath', 0;
test_requires_network 'www.pitchforkmedia.com:80';

plan 'no_plan';
run_eval_expected;

__END__

=== Test pitchforkmedia
--- input config
global:
  cache:
    class: Plagger::Cache::Null
plugins:
  - module: CustomFeed::Debug
    config:
      title: Pitchforkmedia
      entry:
        - title: Pitchfork Feature: Interview: Thom Yorke
          link: http://www.pitchforkmedia.com/article/feature/37863/
  - module: Filter::EntryFullText
--- expected
ok $context->update->feeds->[0]->entries->[0]->body;

