use t::TestPlagger;

test_plugin_deps;
test_requires_network;

plan 'no_plan';
run_eval_expected;

__END__

=== Test www.dailymotion.com
--- input config
global:
  cache:
    class: Plagger::Cache::Null

plugins:
  - module: CustomFeed::Debug
    config:
      title: foo
      entry:
        - title: foo
          link:  http://www.dailymotion.com/video/xg0xu_sid-in-his-new-bed

  - module: Filter::FindEnclosures
--- expected
is $context->update->feeds->[0]->entries->[0]->enclosure->url, 'http://www.dailymotion.com/get/10/320x240/flv/747714.flv?key=104de2f55fbbebc2e8e746e8bce8dc6c1270c71';

