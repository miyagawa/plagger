use strict;
use utf8;
use t::TestPlagger;

test_plugin_deps;
plan 'no_plan';

run_eval_expected;

__END__
=== translate Lou style
--- input config
plugins:
  - module: CustomFeed::Debug
    config:
      title: feed title
      entry:
        - title: test entry
          link: http://blog.example.com/sample
          body: "今年もよろしくお願いします。"
  - module: Filter::Lou

--- expected
is $context->update->feeds->[0]->entries->[0]->body, 
   "ディスイヤーもよろしくプリーズします。";

=== translate Lou style (HTML markup)
--- input config
plugins:
  - module: CustomFeed::Debug
    config:
      title: feed title
      entry:
        - title: test entry
          link: http://blog.example.com/sample
          body: "美しい国、日本を考えています。"
  - module: Filter::Lou
    config:
      lou_rate: 100
      html_fx_rate: 100

--- expected
like $context->update->feeds->[0]->entries->[0]->body, 
   qr{^
   <FONT.*?>ビューティフル<.*?/FONT>な国、<FONT.*?>ジャパン<.*?/FONT>を
   <FONT.*?>シンクアバウト<.*?/FONT>しています。
   $}x;

=== translate Lou style (With <ruby>)
--- input config
plugins:
  - module: CustomFeed::Debug
    config:
      title: feed title
      entry:
        - title: test entry
          link: http://blog.example.com/sample
          body: "信頼に報いなければならぬ"
  - module: Filter::Lou
    config:
      format: "<ruby><rb>%s</rb><rp>（</rp><rt>%s</rt><rp>）</rp></ruby>"

--- expected
is $context->update->feeds->[0]->entries->[0]->body, 
    "<ruby><rb>トラスト</rb><rp>（</rp><rt>信頼</rt><rp>）</rp></ruby>に報いなければならぬ";

