use strict;
use FindBin;

use t::TestPlagger;

plan tests => 1 * blocks;

run_eval_expected;

__END__

=== Test simple keyword
--- input config
global:
  log:
    level: error
  assets_path: $FindBin::Bin/../../../assets
plugins:
  - module: Subscription::Planet
    config:
      keyword: foo
  - module: Aggregator::Null
--- expected
is $context->subscription->feeds->[0]->url, 'http://feeds.technorati.com/feed/posts/tag/foo', $block->name

=== Test keyword with space in it
--- input config
global:
  log:
    level: error
  assets_path: $FindBin::Bin/../../../assets
plugins:
  - module: Subscription::Planet
    config:
      keyword: foo bar
  - module: Aggregator::Null
--- expected
is $context->subscription->feeds->[0]->url, 'http://feeds.technorati.com/feed/posts/tag/foo+bar', $block->name;

=== Test multibyte keyword
--- input config
global:
  log:
    level: error
  assets_path: $FindBin::Bin/../../../assets
plugins:
  - module: Subscription::Planet
    config:
      keyword: ぷらがー
  - module: Aggregator::Null
--- expected
is $context->subscription->feeds->[0]->url, 'http://feeds.technorati.com/feed/posts/tag/%E3%81%B7%E3%82%89%E3%81%8C%E3%83%BC', $block->name;

=== Test keyword and URL
--- input config
global:
  log:
    level: error
  assets_path: $FindBin::Bin/../../../assets
plugins:
  - module: Subscription::Planet
    config:
      keyword: Plagger
      url: http://plagger.org/
  - module: Aggregator::Null
--- expected
is $context->subscription->feeds->[-1]->url, "http://www.bloglines.com/search?q=bcite:http%3A%2F%2Fplagger.org%2F&ql=any&s=f&pop=n&news=m&n=100&format=rss", $block->name;

=== Test lang=ja
--- input config
global:
  log:
    level: error
  assets_path: $FindBin::Bin/../../../assets
plugins:
  - module: Subscription::Planet
    config:
      keyword: Plagger
      lang: ja
  - module: Aggregator::Null
--- expected
is $context->subscription->feeds->[0]->url, "http://www.feedster.jp/search/type/rss/Plagger", $block->name;

=== Test lang=ja with euc-jp
--- input config
global:
  log:
    level: error
  assets_path: $FindBin::Bin/../../../assets
plugins:
  - module: Subscription::Planet
    config:
      keyword: しょこたん
      lang: ja
  - module: Aggregator::Null
--- expected
is $context->subscription->feeds->[1]->url, "http://blog-search.yahoo.co.jp/rss?p=%A4%B7%A4%E7%A4%B3%A4%BF%A4%F3", $block->name;

