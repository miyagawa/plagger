use strict;
use t::TestPlagger;

test_plugin_deps;
test_requires_network;
plan 'no_plan';
run_eval_expected;

__END__

=== Loading Filter::StripRSSAd
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - http://feeds.feedburner.com/boingboing/iBag
  - module: Filter::StripRSSAd
--- expected
unlike $context->update->feeds->[0]->entries->[0]->body, qr/~a/;



