use strict;
use t::TestPlagger;

test_plugin_deps;
plan 'no_plan';
run_eval_expected;

__END__

=== test file
--- input config
plugins:
  - module: Subscription::OPML
    config:
      url: file://$t::TestPlagger::BaseDirURI/t/samples/opml.xml
  - module: Aggregator::Null
--- expected
is $context->subscription->feeds->[0]->url, "http://blog.bulknews.net/mt/index.rdf";
is $context->subscription->feeds->[0]->link, "http://blog.bulknews.net/mt/";
is $context->subscription->feeds->[0]->title, "blog.bulknews.net";

=== test nested subs
--- input config
plugins:
  - module: Subscription::OPML
    config:
      url: file://$t::TestPlagger::BaseDirURI/t/samples/opml-nested.xml
  - module: Aggregator::Null
--- expected
my @feeds = sort { $a->url cmp $b->url } $context->subscription->feeds;

is $feeds[0]->url, "http://blog.bulknews.net/mt/index.rdf";
is $feeds[0]->link, "http://blog.bulknews.net/mt/";
is $feeds[0]->title, "blog.bulknews.net";
is_deeply $feeds[0]->tags, [ 'Foo' ];

is $feeds[1]->url, "http://subtech.g.hatena.ne.jp/miyagawa/rss";
is $feeds[1]->link, "http://subtech.g.hatena.ne.jp/miyagawa/";
is $feeds[1]->title, "Bulknews::Subtech";
is_deeply $feeds[1]->tags, [ 'Bar', 'Baz' ];
