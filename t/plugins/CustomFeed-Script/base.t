use strict;
use t::TestPlagger;

test_plugin_deps;
plan 'no_plan';
run_eval_expected;

__END__

===
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - script://$t::TestPlagger::BaseDirURI/t/samples/scraper.pl
  - module: CustomFeed::Script
--- expected
is $context->update->feeds->[0]->title, "Foo Bar";
is $context->update->feeds->[0]->link, "http://example.com/";
is $context->update->feeds->[0]->count, 2;
is $context->update->feeds->[0]->entries->[0]->title, "Entry 1";
is $context->update->feeds->[0]->entries->[0]->link, "http://example.com/1";

===
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - script://$t::TestPlagger::BaseDirURI/t/samples/scraper-yaml.pl
  - module: CustomFeed::Script
--- expected
is $context->update->feeds->[0]->title, "Foo Bar";
is $context->update->feeds->[0]->link, "http://example.com/";
is $context->update->feeds->[0]->count, 2;
is $context->update->feeds->[0]->entries->[0]->title, "Entry 1";
is $context->update->feeds->[0]->entries->[0]->link, "http://example.com/1";

===
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - script://$t::TestPlagger::BaseDirURI/t/samples/scraper-args.pl 'Foo Bar' baz
  - module: CustomFeed::Script
--- expected
is $context->update->feeds->[0]->title, "Foo Bar";
is $context->update->feeds->[0]->link, "http://example.com/";
is $context->update->feeds->[0]->description, "baz";

===
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - script://$t::TestPlagger::BaseDirURI/t/samples/scraper-yaml-syck.pl
  - module: CustomFeed::Script
--- expected
is $context->update->feeds->[0]->title, "Foo Bar";
is $context->update->feeds->[0]->link, "http://example.com/";
is $context->update->feeds->[0]->count, 2;
is $context->update->feeds->[0]->entries->[0]->title, "Entry 1";
is $context->update->feeds->[0]->entries->[0]->link, "http://example.com/1";
