use strict;
use t::TestPlagger;

plan skip_all => "This test doesn't work on non-Windows machine";

test_plugin_deps;
plan 'no_plan';
run_eval_expected;

__END__

=== Loading Notify::Audio
--- input config
plugins:
  - module: Notify::Audio
--- expected
ok 1, $block->name;
