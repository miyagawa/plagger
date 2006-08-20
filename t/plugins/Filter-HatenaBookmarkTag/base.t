use strict;
use t::TestPlagger;

test_plugin_deps;
plan skip_all => 'The site it tries to test is unreliable.' unless $ENV{TEST_UNRELIABLE_NETWORK};
test_requires_network;

plan 'no_plan';
run_eval_expected;

__END__

=== Loading Filter::HatenaBookmarkTag
--- input config
plugins:
  - module: CustomFeed::Debug
    config:
      title: foo
      entry:
        - title: bar
          link: http://gigazine.net/
  - module: Filter::HatenaBookmarkTag
--- expected
ok $context->update->feeds->[0]->entries->[0]->tags->[0];
