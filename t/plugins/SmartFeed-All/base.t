use strict;
use t::TestPlagger;

plan tests => 4;
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
is @{$context->update->feeds}, 3;
is @{$context->update->feeds->[2]->entries}, 6;
is $context->update->feeds->[2]->id, "smartfeed:all";
is $context->update->feeds->[2]->title, "All Entries";
