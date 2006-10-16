use strict;
use t::TestPlagger;

test_plugin_deps;
plan 'no_plan';
run_eval_expected;

__END__

=== Loading Bundle::Defaults
--- input config
plugins:
  - module: Bundle::Defaults
--- expected
ok 1, $block->name;
