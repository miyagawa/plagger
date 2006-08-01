use strict;
use FindBin;
use t::TestPlagger;

plan 'no_plan';
run_eval_expected;

__END__

=== run hook once
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
