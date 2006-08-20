use utf8;
use t::TestPlagger;

plan 'no_plan';
run_eval_expected;

__END__

=== Break Entries (5+2)
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/rss-full.xml
        - file://$t::TestPlagger::BaseDirURI/t/samples/atom-category.xml
  - module: Filter::BreakEntriesToFeeds
--- expected
is $context->update->count, 7;
is $context->update->feeds->[0]->title, 'Bulknews::Subtech';
is $context->update->feeds->[0]->link, 'http://subtech.g.hatena.ne.jp/miyagawa/';
is $context->update->feeds->[0]->count, 1;
is $context->update->feeds->[1]->title, 'Bulknews::Subtech';
is $context->update->feeds->[1]->link, 'http://subtech.g.hatena.ne.jp/miyagawa/';
is $context->update->feeds->[1]->count, 1;

=== Break Entries with use_entry_title
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/rss-full.xml
        - file://$t::TestPlagger::BaseDirURI/t/samples/atom-category.xml
  - module: Filter::BreakEntriesToFeeds
    config:
      use_entry_title: 1
--- expected
is $context->update->count, 7;
is $context->update->feeds->[0]->title, ' タイプ数カウンターをビジュアル表示';
is $context->update->feeds->[0]->link, 'http://subtech.g.hatena.ne.jp/miyagawa/';
is $context->update->feeds->[0]->count, 1;

=== Break Entries with Rule (1+2)
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/rss-full.xml
        - file://$t::TestPlagger::BaseDirURI/t/samples/atom-category.xml
  - module: Filter::BreakEntriesToFeeds
    rule:
      expression: \$args->{feed}->link !~ /hatena/
--- expected
is $context->update->count, 3;
is $context->update->feeds->[0]->title, 'Bulknews::Subtech';
is $context->update->feeds->[0]->count, 5;
is $context->update->feeds->[1]->count, 1;
is $context->update->feeds->[2]->count, 1;

