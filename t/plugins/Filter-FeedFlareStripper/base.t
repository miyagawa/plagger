use strict;
use t::TestPlagger;

test_plugin_deps;
plan 'no_plan';
run_eval_expected;

__END__

=== Loading Filter::eedFlareStripper
--- input config
plugins:
  - module: CustomFeed::Debug
    config:
      title: foo
      entry:
        - title: test entry
          link: http://www.example.com
          body: this entry is test.<div class="feedflare">Feed Flare</div>
  - module: Filter::FeedFlareStripper
--- expected
is $context->update->feeds->[0]->entries->[0]->body, 'this entry is test.'

