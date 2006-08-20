use strict;
use t::TestPlagger;

plan 'no_plan';
run_eval_expected;

__END__

=== test file
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/rss-full.xml
        - file://$t::TestPlagger::BaseDirURI/t/samples/rss-20.xml
  - module: SmartFeed::All
--- expected
is 3, @{$context->update->feeds};
is 6, @{$context->update->feeds->[2]->entries};
is $context->update->feeds->[2]->id, "smartfeed:all";
is $context->update->feeds->[2]->title, "All Entries";
