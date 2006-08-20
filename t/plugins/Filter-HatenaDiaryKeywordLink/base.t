use strict;
use t::TestPlagger;

test_requires_network 'b.hatena.ne.jp:80';

test_plugin_deps;
plan 'no_plan';
run_eval_expected;

__END__

=== Loading Filter::HatenaDiaryKeywordLink
--- input config
plugins:
  - module: CustomFeed::Debug
    config:
      title: foo
      entry:
        - title: bar
          link: http://www.example.net
          body: Plagger is a pluggable aggregator
  - module: Filter::HatenaDiaryKeywordLink
--- expected
is $context->update->feeds->[0]->entries->[0]->body, "<a class=\"keyword\" target=\"_blank\" href=\"http://d.hatena.ne.jp/keyword/Plagger\">Plagger</a> is a pluggable aggregator"
