use strict;
use t::TestPlagger;

test_requires('Config::INI::Simple');

plan tests => 1;
run_eval_expected;

__END__
=== testing config.ini
--- input config
global:
  log:
    level: error
plugins:
  - module: Subscription::PlanetINI
    config:
      path: $FindBin::Bin/config.ini
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

