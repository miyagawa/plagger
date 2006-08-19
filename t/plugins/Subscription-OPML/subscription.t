use strict;
use t::TestPlagger;

test_plugin_deps;
plan tests => 3;

diag "This test will raise warnings due to XML::OPML internal, but it's harmless";
run_eval_expected;

__END__

=== test file
--- input config
plugins:
  - module: Subscription::OPML
    config:
      url: file://$t::TestPlagger::BaseDirURI/t/samples/opml.xml
  - module: Aggregator::Null
--- expected
is $context->subscription->feeds->[0]->url, "http://blog.bulknews.net/mt/index.rdf";
is $context->subscription->feeds->[0]->link, "http://blog.bulknews.net/mt/";
is $context->subscription->feeds->[0]->title, "blog.bulknews.net";
