use strict;
use utf8;
use t::TestPlagger;

test_plugin_deps;
plan 'no_plan';
run_eval_expected;

__END__
===
--- input config
plugins:
  - module: CustomFeed::Debug
    config:
      title: Foo Bar
      entry:
        - title: Bar Baz
          body: |
            デルタブルース（Delta Blues）は、日本の競走馬。2004年の菊花賞の優勝馬である。馬名の由来は母名からの連想で、「ミシシッピ河口の三角州地帯を起源とする荒々しいブルース」となっている。
            2003年11月29日京都競馬場芝1600m戦でデビュー。結果は7着であった。このレース以降、2000m以上の距離のレースを使われることになる。未勝利戦（一度格上挑戦がある）でも2着2回、4着2回と勝ちきれず、2004年4月17日、福島競馬場にて6戦目で初勝利をあげる。次走の青葉賞では13着と惨敗。その後500万を勝って休養に入る。秋緒戦は5着に敗れたが、続く1000万条件戦を勝利し菊花賞に出走した。
  - module: Summary::Japanese
--- expected
is $context->update->feeds->[0]->entries->[0]->summary->type, 'text';
like $context->update->feeds->[0]->entries->[0]->summary->data, qr/デルタブルース（Delta Blues）は、日本の競走馬。/;


