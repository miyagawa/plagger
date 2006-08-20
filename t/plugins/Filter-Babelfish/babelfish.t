use strict;
use utf8;
use FindBin;
use t::TestPlagger;

test_plugin_deps;
plan skip_all => 'The site it tries to test is unreliable.' unless $ENV{TEST_UNRELIABLE_NETWORK};
test_requires_network;

plan tests => 8;

run_eval_expected;

__END__
=== Test without Babelfish
--- input config
global:
  cache:
    class: Plagger::Cache::Null
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$FindBin::Bin/../../samples/babelfish.xml
--- expected
is $context->update->feeds->[0]->entries->[0]->title, '猫';
sleep(1);
is $context->update->feeds->[0]->entries->[0]->body, '犬';
sleep(1);

=== Test with Babelfish
--- input config
global:
  cache:
    class: Plagger::Cache::Null
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
sleep(1);
like $context->update->feeds->[0]->entries->[0]->body, qr/[dD]og/;
sleep(1);

=== Test with prepend_original
--- input config
global:
  cache:
    class: Plagger::Cache::Null
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
sleep(1);
like $context->update->feeds->[0]->entries->[0]->body, qr/犬.*[dD]og/s;
sleep(1);

=== Test with Babelfish w GuessLanguage
--- input config
global:
  cache:
    class: Plagger::Cache::Null
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$FindBin::Bin/../../samples/babelfish.xml
  - module: Filter::Babelfish
    config:
#      source: Japanese
      destination: English
      service: Google
      prepend_original: 0
--- expected
like $context->update->feeds->[0]->entries->[0]->title, qr/[cC]at/;
sleep(1);
like $context->update->feeds->[0]->entries->[0]->body, qr/[dD]og/;

