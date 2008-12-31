use t::TestPlagger;
use utf8;

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
        - title: foo
          link: http://sankei.jp.msn.com/life/trend/081231/trd0812311301003-n1.htm
  - module: Filter::EntryFullText
--- expected
is $context->update->feeds->[0]->entries->[0]->title, '【今年はネコ年だった】ひこにゃん、スーパー駅長、ネコカフェ−関西はネコで盛り上がったのだった';

