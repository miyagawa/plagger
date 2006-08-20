use strict;
use t::TestPlagger;

test_requires_network 'www.odeo.com:80';

plan tests => 4;
run_eval_expected;

__END__

=== test file
--- input config 
plugins:
  - module: Subscription::Odeo
    config:
      account: TatsuhikoMiyagawa

  - module: Aggregator::Null
--- expected
ok $context->subscription->feeds->[0]->url;
ok $context->subscription->feeds->[1]->title;
ok $context->subscription->feeds->[0]->url;
ok $context->subscription->feeds->[1]->title;