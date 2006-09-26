use strict;
use t::TestPlagger;

test_plugin_deps;
plan skip_all => 'The site it tries to test is unreliable.' unless $ENV{TEST_UNRELIABLE_NETWORK};
test_requires_network;

plan 'no_plan';
run_eval_expected;

__END__

=== Loading Filter::LivedoorClipUsersCount
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - http://clip.livedoor.com/rss/hot

  - module: Filter::LivedoorClipUsersCount
--- expected
ok $context->update->feeds->[0]->entries->[0]->meta->{livedoorclip_users};
