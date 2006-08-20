use strict;
use t::TestPlagger;

test_plugin_deps;
plan 'no_plan';
run_eval_expected;

__END__

=== Loading Filter::ResolveRelativeLink
--- input config
plugins:
  - module: CustomFeed::Debug
    config:
      title: foo
      link: http://www.example.com/show/foo
      entry:
        - title: bar
          body: <a href="/foo/bar">Plagger</a> is a pluggable aggregator
  - module: Filter::ResolveRelativeLink
--- expected
is $context->update->feeds->[0]->entries->[0]->body, '<a href="http://www.example.com/foo/bar">Plagger</a> is a pluggable aggregator'
