use strict;
use t::TestPlagger;

test_requires_network 'd.hatena.ne.jp:80';

plan 'no_plan';

run_eval_expected;

__END__

=== Test Simple CustomFeed
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - url: http://d.hatena.ne.jp/antipop/20050628/1119966355
          meta:
            follow_xpath: //ul[@class="xoxo" or @class="subscriptionlist"]//a

  - module: CustomFeed::Simple

--- expected
is $context->update->feeds->[0]->link, 'http://d.hatena.ne.jp/antipop/20050628/1119966355';
ok $context->update->feeds->[0]->count;
is $context->update->feeds->[0]->entries->[0]->title, 'blog.bulknews.net';
is $context->update->feeds->[0]->entries->[0]->link,  'http://blog.bulknews.net/mt/';
is $context->update->feeds->[0]->entries->[1]->title, 'bulknews.typepad.com';
is $context->update->feeds->[0]->entries->[1]->link,  'http://bulknews.typepad.com/';
