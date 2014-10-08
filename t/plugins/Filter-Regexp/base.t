use strict;
use t::TestPlagger;

plan 'no_plan';
run_eval_expected;

__END__

=== Loading Filter::Regexp
--- input config
plugins:
  - module: CustomFeed::Debug
    config:
      title: foo
      entry:
        - title: bar
          body: Plagger
        - title: baz
          body: Plagger, she said.
  - module: Filter::Regexp
    config:
      regexp: s/Plagger/Plagger is a pluggable aggregator/g
      text_only: 1
--- expected
is $context->update->feeds->[0]->entries->[0]->body, "Plagger is a pluggable aggregator";
is $context->update->feeds->[0]->entries->[1]->body, "Plagger is a pluggable aggregator, she said.";
