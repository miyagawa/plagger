use strict;
use t::TestPlagger;

test_requires_network 'blog.goo.ne.jp:80';
test_plugin_deps;

plan tests => 6;
run_eval_expected;

__END__

=== test file
--- input config 
plugins:
  - module: Subscription::PingServer
    config:
      fetch_items: 20
      servers:
        - url: http://blog.goo.ne.jp/index.php?fid=freshEntryChangesXml
  - module: Aggregator::Null
--- expected
ok $context->subscription->feeds->[0]->url;
ok $context->subscription->feeds->[0]->link;
ok $context->subscription->feeds->[0]->title;
ok $context->subscription->feeds->[19]->url;
ok $context->subscription->feeds->[19]->link;
ok $context->subscription->feeds->[19]->title;


