use strict;
use t::TestPlagger;

plan tests => 2;
run_eval_expected;

__END__

=== Test one
--- input config
plugins:
  - module: Subscription::Feed
    config:
      url: file://$t::TestPlagger::BaseDirURI/t/samples/feed.xml
  - module: Aggregator::Null
--- expected
is $context->subscription->feeds->[0]->url, "http://d.hatena.ne.jp/agw/20060526/1148633449#c";
is $context->subscription->feeds->[1]->url, "http://d.hatena.ne.jp/nirvash/20060517/1147836803#c";
