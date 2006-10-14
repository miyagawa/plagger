use strict;
use t::TestPlagger;

test_plugin_deps;
plan 'no_plan';
run_eval_expected;

__END__

=== By country code
--- input config
plugins:
  - module: CustomFeed::Debug
    config:
      title: Foo
      entry:
        - link: http://d.hatena.ne.jp/
          date: 2006/10/14 12:00:00
  - module: Filter::GuessTimeZoneByDomain
--- expected
is $context->update->feeds->[0]->entries->[0]->date->time_zone->name, "Asia/Tokyo";

=== By IP
--- input config
plugins:
  - module: CustomFeed::Debug
    config:
      title: Foo
      entry:
        - link: http://bulknews.net/
          date: 2006/10/14 12:00:00
  - module: Filter::GuessTimeZoneByDomain
--- expected
is $context->update->feeds->[0]->entries->[0]->date->time_zone->name, "Asia/Tokyo";

=== By IP
--- input config
plugins:
  - module: CustomFeed::Debug
    config:
      title: Foo
      entry:
        - link: http://www.time.co.uk/
          date: 2006/10/14 12:00:00
  - module: Filter::GuessTimeZoneByDomain
--- expected
is $context->update->feeds->[0]->entries->[0]->date->time_zone->name, "Europe/London";

=== Don't use IP::Country
--- input config
plugins:
  - module: CustomFeed::Debug
    config:
      title: Foo
      entry:
        - link: http://www.time.co.uk/
          date: 2006/10/14 12:00:00
  - module: Filter::GuessTimeZoneByDomain
    config:
      use_ip_country: 0
--- expected
is $context->update->feeds->[0]->entries->[0]->date->time_zone->name, "floating";

=== Conflict: CC by default
--- input config
plugins:
  - module: CustomFeed::Debug
    config:
      title: Foo
      entry:
        - link: http://www.sixapart.jp/
          date: 2006/10/14 12:00:00
  - module: Filter::GuessTimeZoneByDomain
--- expected
is $context->update->feeds->[0]->entries->[0]->date->time_zone->name, "Asia/Tokyo";

=== Conflict: Use IP
--- SKIP
--- input config
plugins:
  - module: CustomFeed::Debug
    config:
      title: Foo
      entry:
        - link: http://www.sixapart.jp/
          date: 2006/10/14 12:00:00
  - module: Filter::GuessTimeZoneByDomain
    config:
      conflict_policy: ip
--- expected
is $context->update->feeds->[0]->entries->[0]->date->time_zone->name, "America/New_York";

