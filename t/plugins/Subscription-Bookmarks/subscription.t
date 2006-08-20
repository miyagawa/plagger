use strict;
use t::TestPlagger;

plan tests => 4;
run_eval_expected;

__END__

=== test file
--- input config
plugins:
  - module: Subscription::Bookmarks
    config:
      browser: Mozilla
      path: $t::TestPlagger::BaseDirURI/t/samples/mozilla-bookmarks.html

  - module: Aggregator::Null
--- expected
is $context->subscription->feeds->[0]->url, "http://blog.bulknews.net/mt/";
is $context->subscription->feeds->[0]->title, "blog.bulknews.net";
is $context->subscription->feeds->[1]->url, "http://bulknews.typepad.com/";
is $context->subscription->feeds->[1]->title, "bulknews.typepad.com";

