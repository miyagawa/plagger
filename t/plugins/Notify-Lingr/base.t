use strict;
use t::TestPlagger;

test_plugin_deps;
plan 'no_plan';
run_eval_expected;

__END__

=== Loading Notify::Lingr
--- input config
plugins:
  - module: Notify::Lingr
--- expected
ok 1, $block->name;
