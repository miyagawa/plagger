use strict;
use t::TestPlagger;

test_requires_network;

plan 'no_plan';

run_eval_expected;

__END__

=== Test Google News live
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - http://news.google.com/news?ned=jp&rec=0&topic=s
        - http://news.google.co.jp/news?hl=ja&ned=tjp&q=%E5%9B%B2%E7%A2%81&ie=UTF-8&scoring=d

  - module: CustomFeed::GoogleNews
--- expected
is $context->update->feeds->[0]->link, 'http://news.google.com/news?ned=jp&rec=0&topic=s';
ok $context->update->feeds->[0]->count;

