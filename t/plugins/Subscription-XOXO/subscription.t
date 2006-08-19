use strict;
use t::TestPlagger;

test_plugin_deps;
plan tests => 1;
run_eval_expected;

__END__

=== test file
--- input config 
plugins:
  - module: Subscription::XOXO
    config:
      url: file://$t::TestPlagger::BaseDirURI/t/samples/xoxo.html
  - module: Aggregator::Null
--- expected
my @feeds = map $_->url, $context->subscription->feeds;
is_deeply(
    \@feeds,
    [ 'http://blog.bulknews.net/mt/',
      'http://bulknews.typepad.com/',
      'http://subtech.g.hatena.ne.jp/miyagawa/']
);
