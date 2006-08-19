use strict;
use t::TestPlagger;

test_requires_network 'subtech.g.hatena.ne.jp:80';

plan tests => 1;
run_eval_expected;

__END__

=== test file
--- input config 
plugins:
  - module: Subscription::HatenaGroup
    config:
      group: subtech
  - module: Aggregator::Null
--- expected
ok $context->subscription->feeds->[0]->url;
ok $context->subscription->feeds->[0]->link;
ok $context->subscription->feeds->[0]->title;
ok $context->subscription->feeds->[1]->url;
ok $context->subscription->feeds->[1]->link;
ok $context->subscription->feeds->[1]->title;
