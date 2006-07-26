use strict;
use FindBin;
use t::TestPlagger;

plan tests => 1;
run_eval_expected;

__END__

=== test file
--- input config 
global:
  log:
    level: error
plugins:
  - module: Subscription::File
    config:
      file: $FindBin::Bin/feeds.txt
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

