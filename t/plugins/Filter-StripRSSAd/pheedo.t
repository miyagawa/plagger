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
        - http://jp.techcrunch.com/feed/
        - http://slashdot.jp/slashdotjp.rss
  - module: Filter::StripRSSAd
--- expected
unlike $context->update->feeds->[0]->entries->[0]->body, qr/pheedo/;
unlike $context->update->feeds->[1]->entries->[1]->body, qr/pheedo/;



