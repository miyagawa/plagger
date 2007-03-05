use strict;
use t::TestPlagger;

test_plugin_deps('Subscription::BrowserHistory::Safari');
plan tests => 5	;
run_eval_expected;

__END__

=== test file
--- input config
plugins:
  - module: Subscription::BrowserHistory
    config:
      browser: Safari
      path: $t::TestPlagger::BaseDirURI/t/samples/safari_history.plist
  - module: Aggregator::Null
--- expected
is 2, @{$context->subscription->feeds};
is $context->subscription->feeds->[1]->url, "http://blog.bulknews.net/mt/";
is $context->subscription->feeds->[1]->title, "blog.bulknews.net";
is $context->subscription->feeds->[0]->url, "http://bulknews.typepad.com/";
is $context->subscription->feeds->[0]->title, "bulknews.typepad.com";