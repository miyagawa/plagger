use strict;
use t::TestPlagger;

test_plugin_deps;
test_requires_network 'b.hatena.ne.jp:80';
plan 'no_plan';

sleep 2; # to avoid throttle
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
