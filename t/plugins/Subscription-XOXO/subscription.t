use strict;
use FindBin;
use t::TestPlagger;

plan tests => 1;
run_eval_expected;

__END__

=== test file
--- input config 
plugins:
  - module: Subscription::XOXO
    config:
      url: file:///$FindBin::Bin/feeds.html
  - module: Aggregator::Null
--- expected
my @feeds = map $_->url, $context->subscription->feeds;
is_deeply(
    \@feeds,
    [ 'http://blog.bulknews.net/mt/',
      'http://bulknews.typepad.com/',
      'http://subtech.g.hatena.ne.jp/miyagawa/']
);
