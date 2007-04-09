use strict;
use t::TestPlagger;

test_plugin_deps;
plan 'no_plan';
run_eval_expected;

__END__

=== Loading Aggregator::Async
--- input config
plugins:
  - module: Aggregator::Async
--- expected
ok 1, $block->name;
