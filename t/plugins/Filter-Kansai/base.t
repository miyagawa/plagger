use strict;
use utf8;
use t::TestPlagger;

test_plugin_deps;
plan 'no_plan';
run_eval_expected;

__END__

=== Loading Filter::Kansai
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/rss-full.xml
  - module: Filter::Kansai
--- expected
like $context->update->feeds->[0]->entries->[0]->body, qr/とかはわからへんのが残念/;

