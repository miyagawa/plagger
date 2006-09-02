use strict;
use t::TestPlagger;

test_requires_network;
plan 'no_plan';
run_eval_expected_with_capture;

__END__

=== sixapart.com feed
--- input config
global:
  log:
    level: info
plugins:
  - module: Subscription::Config
    config:
      feed:
        - http://www.sixapart.com/pronet/weblog/

  - module: Filter::FeedBurnerPermalink
--- expected
like $warnings, qr/Permalink rewritten to/;
