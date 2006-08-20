use strict;
use t::TestPlagger;

test_plugin_deps;
plan 'no_plan';
run_eval_expected;

__END__

=== Loading Filter::Emoticon
--- input config
plugins:
  - module: CustomFeed::Debug
    config:
      title: foo
      entry:
        - title: test entry
          body: Yet Another Perl Hacker ;-)
  - module: Filter::Emoticon
    config:
      driver: MSN
    option:
      strict: 1
      xhtml: 0
--- expected
ok 1, $block->name;
is $context->update->feeds->[0]->entries->[0]->body, 'Yet Another Perl Hacker <img src="http://example.com/emo/regular_smile.gif" />'
