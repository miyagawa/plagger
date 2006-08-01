use strict;
use FindBin;
use t::TestPlagger;

test_requires_network;
plan 'no_plan';
run_eval_expected;

__END__

=== EFT -> CFS
--- input config
global:
  assets_path: $FindBin::Bin/../../assets
  log:
    level: error
plugins:
  - module: Subscription::Config
    config:
      feed:
        - url: http://www.asahi.com/
          meta:
            follow_link: national/update/
  - module: Filter::EntryFullText
  - module: CustomFeed::Simple
--- expected
ok $context->update->feeds->[0]->entries->[0]->body;

=== CFS => EFT
--- input config
global:
  assets_path: $FindBin::Bin/../../assets
  log:
    level: error
plugins:
  - module: Subscription::Config
    config:
      feed:
        - http://sportsnavi.yahoo.co.jp/
  - module: CustomFeed::Simple
  - module: Filter::EntryFullText
--- expected
ok $context->update->feeds->[0]->entries->[0]->body;
