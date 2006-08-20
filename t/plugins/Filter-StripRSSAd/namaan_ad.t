use strict;
use t::TestPlagger;

test_plugin_deps;
plan 'no_plan';
run_eval_expected;

__END__

=== Loading Filter::StripRSSAd
--- input config
plugins:
  - module: CustomFeed::Debug
    config:
      title: foo
      entry:
        - title: namaan ad
          link: http://www.namaan.net/ad_rd?0001
          body: this is ad entry.
        - title: not ad entry
          link: http://www.example.com
          body: some text.
  - module: Filter::StripRSSAd
--- expected
is $context->update->feeds->[0]->entries->[0]->title, 'not ad entry'

