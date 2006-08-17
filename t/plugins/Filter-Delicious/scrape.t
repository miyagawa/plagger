use t::TestPlagger;

test_plugin_deps;
test_requires_network 'del.icio.us:80';

plan 'no_plan';
run_eval_expected;

__END__

=== Test hotlist
--- input config
global:
  cache:
    class: Plagger::Cache::Null
plugins:
  - module: CustomFeed::Debug
    config:
      title: foo
      entry:
        - title: bar
          link: http://del.icio.us/
  - module: Filter::Delicious
    config:
      scrape_big_numbers: 1
--- expected
ok $context->update->feeds->[0]->entries->[0]->meta->{delicious_users} > 30;
