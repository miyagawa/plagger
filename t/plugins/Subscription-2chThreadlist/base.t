use strict;
use t::TestPlagger;

plan skip_all => 'The site it tries to test is unreliable.' unless $ENV{TEST_UNRELIABLE_NETWORK};
test_requires_network('rss.s2ch.net:80');
plan tests => 1;
run_eval_expected;

__END__

=== test file
--- input config
plugins:
  - module: Subscription::2chThreadList
    config:
      url: http://rss.s2ch.net/test/-/news19.2ch.net/newsplus/
  - module: Aggregator::Null
--- expected
like $context->subscription->feeds->[0]->url, qr{http://rss\.s2ch\.net/test/\-/news19\.2ch.net/newsplus/\d+/$};
