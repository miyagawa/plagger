use strict;
use t::TestPlagger;

test_requires_network;
test_plugin_deps;

plan 'no_plan';
run_eval_expected;

__END__

=== Loading Summary::TrackbackRDF
--- input config
plugins:
  - module: Summary::TrackbackRDF
--- expected
ok 1, $block->name;

=== Use Trackback RDF
--- input config
plugins:
  - module: CustomFeed::Debug
    config:
      title: Foo
      entry:
        - title: Foo
          body: XXX Summary::Auto requires body ... could be fixed
          link: http://bulknews.typepad.com/blog/2006/08/plagger_hackath.html
        - title: Bar
          body: XXX Summary::Auto requires body ... could be fixed
          link: http://blog.bulknews.net/mt/archives/002060.html
  - module: Summary::TrackbackRDF
--- expected
unlike $context->update->feeds->[0]->entries->[0]->summary, qr/XXX/;
unlike $context->update->feeds->[0]->entries->[1]->summary, qr/XXX/;

