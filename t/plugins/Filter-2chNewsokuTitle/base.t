use strict;
use utf8;
use t::TestPlagger;

test_plugin_deps;
plan 'no_plan';
run_eval_expected;

__END__

=== Loading Filter::2chNewsokuTitle  
--- input config
plugins:
  - module: Filter::2chNewsokuTitle
--- expected
ok 1, $block->name;

=== Newsokuize entry titles 
--- input config
plugins:
  - module: CustomFeed::Debug
    config:
      title: はてなブックマーク - タグ plagger
      link: http://b.hatena.ne.jp/t/plagger?sort=count
      entry:
        - title: 「とりあえずググる」を卒業！TOPエンジニアの検索術／Ｔｅｃｈ総研
          link: http://rikunabi-next.yahoo.co.jp/tech/docs/ct_s03600.jsp?p=000870
          tags:
            - 仕事術
            - これは便利
        - title: Elementary, ... Googleで「はらへった」と検索するとピザが届くようにするまで
          link: http://e8y.net/blog/2006/07/25/p126.html
          tags:
            - 朝からピザ
  - module: Filter::2chNewsokuTitle 
--- expected
is $context->update->feeds->[0]->entries->[0]->title
   => '【仕事術】 「とりあえずググる」を卒業！TOPエンジニアの検索術／Ｔｅｃｈ総研 【これは便利】';
is $context->update->feeds->[0]->entries->[1]->title
   => '【朝からピザ】 Elementary, ... Googleで「はらへった」と検索するとピザが届くようにするまで';
