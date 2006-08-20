use strict;
use t::TestPlagger;

test_requires_network 'b.hatena.ne.jp:80';

test_plugin_deps;
plan 'no_plan';
run_eval_expected;

__END__

=== Loading Filter::HatenaKeywordTag
--- input config
plugins:
  - module: CustomFeed::Debug
    config:
      title: foo
      entry:
        - title: bar
          link: http://www.example.net
          body: Plagger is a pluggable aggregator
  - module: Filter::HatenaKeywordTag
--- expected
is $context->update->feeds->[0]->entries->[0]->tags->[0], "Plagger"
