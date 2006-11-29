use strict;
use t::TestPlagger;

test_requires_network 'sportsnavi.yahoo.co.jp:80';

plan 'no_plan';

run_eval_expected;

__END__

=== Test Simple CustomFeed
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - url: http://sportsnavi.yahoo.co.jp/index.html
          meta:
            follow_link: /headlines/
 	
  - module: CustomFeed::Simple

--- expected
is $context->update->feeds->[0]->link, 'http://sportsnavi.yahoo.co.jp/index.html';
ok $context->update->feeds->[0]->count;
ok $context->update->feeds->[0]->entries->[0]->title;
ok $context->update->feeds->[0]->entries->[0]->link;

=== Test custom feed title
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - url: http://sportsnavi.yahoo.co.jp/index.html
          title: Sports navi custom!
          meta:
            follow_link: /headlines/
 	
  - module: CustomFeed::Simple

--- expected
is $context->update->feeds->[0]->link, 'http://sportsnavi.yahoo.co.jp/index.html';
ok $context->update->feeds->[0]->count;
ok $context->update->feeds->[0]->entries->[0]->title;
ok $context->update->feeds->[0]->entries->[0]->link;
is $context->update->feeds->[0]->title, 'Sports navi custom!';

