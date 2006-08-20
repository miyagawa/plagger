use strict;
use t::TestPlagger;

test_plugin_deps;
test_requires_network 'b.hatena.ne.jp:80';
plan 'no_plan';

sleep 3; # to avoid throttle
run_eval_expected;

__END__

=== Loading Filter::HatenaBookmarkUsersCount
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - http://b.hatena.ne.jp/hotentry?mode=rss

  - module: Filter::HatenaBookmarkUsersCount
--- expected
ok $context->update->feeds->[0]->entries->[0]->meta->{hatenabookmark_users};
