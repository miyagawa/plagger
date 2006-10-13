use strict;
use t::TestPlagger;

test_requires_network;
test_plugin_deps;

plan 'no_plan';
run_eval_expected;

__END__

=== use Hatebu Atom feed to get summary
--- input config
plugins:
  - module: CustomFeed::Debug
    config:
      title: Foo
      entry:
        - title: Foo Bar
          link: http://bulknews.typepad.com/blog/2006/08/plagger_hackath.html
          body: XXX Summary::Auto requires body to work ... Hmm.
  - module: Summary::HatenaBookmark
--- expected
unlike $context->update->feeds->[0]->entries->[0]->summary, qr/XXX/;

=== Something bogus
--- input config
plugins:
  - module: CustomFeed::Debug
    config:
      title: Foo
      entry:
        - title: Foo Bar
          link: http://bulknews.typepad.com/blog/2006/08/plagger_hackath.htmlXXX
          body: XXX Summary::Auto requires body to work ... Hmm.
  - module: Summary::HatenaBookmark
--- expected
like $context->update->feeds->[0]->entries->[0]->summary, qr/XXX/;
