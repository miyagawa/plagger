use strict;
use t::TestPlagger;

test_plugin_deps;
plan 'no_plan';
run_eval_expected;

__END__

=== Loading Filter::2chRSSContent
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/top10news.xml

  - module: Filter::2chRSSContent
--- expected
is $context->update->feeds->[0]->count, 1;
ok $context->update->feeds->[0]->entries->[0]->date;
ok $context->update->feeds->[0]->entries->[0]->author;
ok ! grep { $_->title =~ /^\d+\-$/ }
          $context->update->feeds->[0]->entries;
