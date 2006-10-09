use strict;
use t::TestPlagger;

test_plugin_deps;
plan 'no_plan';
run_eval_expected;

__END__

=== Loading Notify::OpenBrowser::FirefoxRemote
--- input config
plugins:
  - module: Notify::OpenBrowser::FirefoxRemote
--- expected
ok 1, $block->name;
