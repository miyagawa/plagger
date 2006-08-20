use strict;
use t::TestPlagger;

test_plugin_deps;
test_requires_network('localhost:8081');
plan 'no_plan';
run_eval_expected;

__END__

=== Loading Filter::POPFile
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/atom10-example.xml
  - module: Filter::POPFile
    config:
      proxy: http://localhost:8081/RPC2
      training: 0
--- expected
ok $context->update->feeds->[0]->entries->[0]->tags->[0] ne 'spam';
