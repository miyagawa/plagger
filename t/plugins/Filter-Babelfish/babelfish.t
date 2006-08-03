use strict;
use FindBin;
use t::TestPlagger;
use utf8;

test_plugin_deps;
test_requires_network;

plan tests => 6;

run_eval_expected;

__END__
=== Test without Babelfish
--- input config
global:
  cache:
    class: Plagger::Cache::Null
  log:
    level: error
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$FindBin::Bin/../../samples/babelfish.xml
--- expected
is $context->update->feeds->[0]->entries->[0]->title, '猫';
is $context->update->feeds->[0]->entries->[0]->body, '犬';

=== Test with Babelfish
--- input config
global:
  cache:
    class: Plagger::Cache::Null
  log:
    level: error
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$FindBin::Bin/../../samples/babelfish.xml
  - module: Filter::Babelfish
    config:
      source: Japanese
      destination: English
      service: Google
      prepend_original: 0
--- expected
like $context->update->feeds->[0]->entries->[0]->title, qr/[cC]at/;
like $context->update->feeds->[0]->entries->[0]->body, qr/[dD]og/;

=== Test with prepend_original
--- input config
global:
  cache:
    class: Plagger::Cache::Null
  log:
    level: error
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$FindBin::Bin/../../samples/babelfish.xml
  - module: Filter::Babelfish
    config:
      source: Japanese
      destination: English
      service: Google
      prepend_original: 1
--- expected
like $context->update->feeds->[0]->entries->[0]->title, qr/猫.*[cC]at/s;
like $context->update->feeds->[0]->entries->[0]->body, qr/犬.*[dD]og/s;
