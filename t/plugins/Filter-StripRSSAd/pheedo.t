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
        - http://www.appleinsider.com/appleinsider.rss
  - module: Filter::StripRSSAd
--- expected
for my $feed ( $context->update->feeds ) {
    unlike $feed->entries->[0]->body, qr/pheedo/;
}
