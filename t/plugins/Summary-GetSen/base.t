use strict;
use utf8;
use t::TestPlagger;

test_plugin_deps;
plan 'no_plan';
run_eval_expected;

__END__

=== Loading Summary::GetSen
--- input config
plugins:
  - module: CustomFeed::Debug
    config:
      title: Foo Bar
      entry:
        - title: Bar Baz
          body: |
            　米ＣＮＮが１７日に発表した米国人を対象とする世論調査で、北朝鮮を米国への「差し迫った脅威」と考える人が２０％にとどまることが分かった。北朝鮮の９日の核実験実施後の調査だが、米国と北朝鮮は地理的にも太平洋をはさんで距離が遠く、冷静な反応につながっているようだ。
            　これによると、北朝鮮について「長期的な脅威」と考える人が６４％と半数を超えた。「全く脅威ではない」と考える人も１３％あった。
  - module: Summary::GetSen
--- expected
is $context->update->feeds->[0]->entries->[0]->summary->type, 'text';
like $context->update->feeds->[0]->entries->[0]->summary->data, qr/米CNNが17日に発表した/;

