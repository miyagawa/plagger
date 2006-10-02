use t::TestPlagger;

plan skip_all => 'The site it tries to test is unreliable.' unless $ENV{TEST_UNRELIABLE_NETWORK};
test_plugin_deps;
test_requires_network;

plan 'no_plan';
run_eval_expected;

__END__

=== Test stage6.divx.com
--- input config
global:
  user_agent:
    agent: Mozilla/5.0 (Windows; U; Windows NT 5.1; ja; rv:1.8.0.7) Gecko/20060909 Firefox/1.5.0.7
  cache:
    class: Plagger::Cache::Null

plugins:

  - module: CustomFeed::Debug
    config:
      title: foo
      entry:
        - title: foo
          link:  http://stage6.divx.com/Hak5/show_video/1009678

  - module: Filter::FindEnclosures
--- expected
is $context->update->feeds->[0]->entries->[0]->enclosure->url, 'http://video.stage6.com/65184/1009678.divx';
