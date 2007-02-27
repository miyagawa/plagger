use strict;
use t::TestPlagger;

test_plugin_deps;
plan 'no_plan';
run_eval_expected;

__END__

===
--- input config
plugins:
  - module: CustomFeed::Debug
    config:
      title: foo
      entry:
        - title: 1
        - title: 2
        - title: 3
  - module: Filter::Rule
    rule:
      - module: RecentN
        count: 2
--- expected
is $context->update->feeds->[0]->count, 2;
is $context->update->feeds->[0]->entries->[0]->title, 1;
