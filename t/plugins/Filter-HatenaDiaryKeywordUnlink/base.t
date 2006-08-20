use strict;
use t::TestPlagger;

plan 'no_plan';
run_eval_expected;

__END__

=== Loading Filter::HatenaDiaryKeywordUnlink
--- input config
plugins:
  - module: CustomFeed::Debug
    config:
      title: foo
      entry:
        - title: bar
          body: <a class="keyword" href="http://d.hatena.ne.jp/keyword/Plagger">Plagger</a> is a pluggable aggregator
  - module: Filter::HatenaDiaryKeywordUnlink
--- expected
is $context->update->feeds->[0]->entries->[0]->body, "Plagger is a pluggable aggregator"
