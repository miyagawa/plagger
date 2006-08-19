use strict;
use t::TestPlagger;

test_plugin_deps;
plan tests => 1;
run_eval_expected;

__END__
=== Test FOAF
--- input config
plugins:
  - module: Subscription::FOAF
    config:
      url: file://$t::TestPlagger::BaseDirURI/t/samples/sample.foaf
  - module: Aggregator::Null
--- expected
my @feeds = map $_->url, $context->subscription->feeds;
is_deeply(
    \@feeds,
    [ 'http://usefulinc.com/edd/blog/rss91',
      'http://www.netsplit.com/blog/index.rss',
      'http://www.gnome.org/~jdub/blog/?flav=rss',
      'http://blog.clearairturbulence.org/?flav=rss',
      'http://www.hadess.net/diary.rss' ],
);
