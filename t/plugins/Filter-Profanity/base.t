use strict;
use t::TestPlagger;

test_plugin_deps;
plan 'no_plan';
run_eval_expected;

__END__

=== Loading Filter::Profanity
--- input config
plugins:
  - module: CustomFeed::Debug
    config:
      title: foo
      entry:
        - title: bar
          link: http://www.example.net
          body: Theare are some words you may not say like jack-off, drink-piss or milk-my-breasts.
  - module: Filter::Profanity
--- expected
ok 1, $block->name;
is $context->update->feeds->[0]->entries->[0]->body, 'Theare are some words you may not say like !@$*%#~!, !@$*%#~!@$ or !@$*%#~!@$*%#~!.';
