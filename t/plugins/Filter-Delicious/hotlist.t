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
  - module: Subscription::Config
    config:
      feed:
       - http://del.icio.us/rss/
  - module: Filter::Delicious
--- expected
ok $context->update->feeds->[0]->entries->[0]->tags->[0];
ok $context->update->feeds->[0]->entries->[0]->meta->{delicious_users};
ok $context->update->feeds->[0]->entries->[0]->meta->{delicious_rate};
