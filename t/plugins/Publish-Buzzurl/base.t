use strict;
use t::TestPlagger;

test_plugin_deps;
plan 'no_plan';
run_eval_expected;

__END__

=== Loading Publish::Buzzurl
--- input config
plugins:
  - module: Publish::Buzzurl
--- expected
ok 1, $block->name;
