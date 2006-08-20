use strict;
use t::TestPlagger;

test_requires_network;
test_plugin_deps;
plan tests => 3;
run_eval_expected;

__END__

=== Loading Filter::URLBL
--- input config
plugins:
  - module: CustomFeed::Debug
    config:
      title: feed title
      entry:
        - title: spam entry
          link: http://casino-jp.com/foo
          body: spam spam spam
        - title: test entry
          link: http://www.example.com/
          body: some text
  - module: Filter::URLBL
    config:
      dnsbl: rbl.bulkfeeds.jp
--- expected
ok 1, $block->name;
is $context->update->feeds->[0]->entries->[0]->rate, '-1';
is $context->update->feeds->[0]->entries->[1]->rate, '0';
