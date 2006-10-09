use strict;
use t::TestPlagger;

test_plugin_deps;
plan 'no_plan';
run_eval_expected;

__END__

=== Loading Notify::OpenBrowser
--- input config
plugins:
  - module: Notify::OpenBrowser
--- expected
ok 1, $block->name;
