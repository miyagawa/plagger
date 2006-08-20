use strict;
use t::TestPlagger;

test_plugin_deps('Subscription::Bookmarks::Safari');
plan tests => 7;
run_eval_expected;

__END__

=== test file
--- input config
plugins:
  - module: Subscription::Bookmarks
    config:
      browser: Safari
      path: $t::TestPlagger::BaseDirURI/t/samples/safari_bookmarks.plist
  - module: Aggregator::Null
--- expected
is 2, @{$context->subscription->feeds};
is $context->subscription->feeds->[1]->url, "http://plagger.org/trac/log/";
is $context->subscription->feeds->[1]->title, "/ (log) - Plagger - Trac";
is $context->subscription->feeds->[1]->tags->[0], "plagger";
is $context->subscription->feeds->[0]->url, "http://del.icio.us/";
is $context->subscription->feeds->[0]->title, "del.icio.us";
is $context->subscription->feeds->[0]->tags->[0], "BookmarksBar";
