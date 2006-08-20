use strict;
use t::TestPlagger;

test_plugin_deps;
plan 'no_plan';
run_eval_expected;

__END__

=== Loading Filter::Romanize
--- input config
plugins:
  - module: CustomFeed::Debug
    config:
      title: foo
      entry:
        - title: bar
          body: あいうえおカキクケコ本日は晴天なり
  - module: Filter::Romanize::Japanese
    config:
      text_only: 1
--- expected
is $context->update->feeds->[0]->entries->[0]->body, 'aiueokakikukekohonjitsuhaseitennari'
