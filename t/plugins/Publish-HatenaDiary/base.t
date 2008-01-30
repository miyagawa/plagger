use strict;
use t::TestPlagger;

test_plugin_deps;
plan 'no_plan';
run_eval_expected;

__END__

=== Loading Publish::HatenaDiary
--- input config
plugins:
  - module: Publish::HatenaDiary
--- expected
ok 1, $block->name;
