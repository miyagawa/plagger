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
        - link: foo
  - module: Filter::Rule
    rule:
      - module: URLBL
        dnsbl: rbl.bulkfeeds.jp
--- expected
ok 1;
