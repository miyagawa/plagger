use strict;
use t::TestPlagger;

test_plugin_deps;
plan skip_all => 'The site it tries to test is unreliable.' unless $ENV{TEST_UNRELIABLE_NETWORK};
test_requires_network;

plan 'no_plan';
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
