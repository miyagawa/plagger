use strict;
use t::TestPlagger;

test_plugin_deps;
plan 'no_plan';
run_eval_expected;

__END__

=== ForceTimeZone against floating
--- input config
global:
  timezone: Asia/Tokyo
plugins:
  - module: CustomFeed::Debug
    config:
      title: Foo
      entry:
        - date: 2006/10/14 12:00:00
  - module: Filter::ForceTimeZone
--- expected
is $context->update->feeds->[0]->entries->[0]->date->iso8601, "2006-10-14T12:00:00";
is $context->update->feeds->[0]->entries->[0]->date->time_zone->name, "Asia/Tokyo";

=== ForceTimeZone against other TZ
--- input config
global:
  timezone: Asia/Tokyo
plugins:
  - module: CustomFeed::Debug
    config:
      title: Foo
      entry:
        - date: 2006/10/14 12:00:00 -0700
  - module: Filter::ForceTimeZone
--- expected
is $context->update->feeds->[0]->entries->[0]->date->iso8601, "2006-10-15T04:00:00";
is $context->update->feeds->[0]->entries->[0]->date->time_zone->name, "Asia/Tokyo";

