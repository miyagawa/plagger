use strict;
use t::TestPlagger;

test_plugin_deps;
plan tests => 4;
run_eval_expected;

__END__

=== Loading Filter::FloatingDateTime
--- input config
global:
  timezone: America/Chicago
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/hatena-rss.xml
  - module: Filter::FloatingDateTime
--- expected
ok 1, $block->name;
isa_ok $context->update->feeds->[0]->entries->[0]->date, 'Plagger::Date';
is $context->update->feeds->[0]->entries->[0]->date->time_zone->is_floating, '0';
is $context->update->feeds->[0]->entries->[0]->date->serialize, '2004-08-20T00:00:00-05:00';
