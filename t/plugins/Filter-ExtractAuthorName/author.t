use strict;
use t::TestPlagger;

test_plugin_deps;
test_requires_network;

plan 'no_plan';
run_eval_expected;

__END__

=== Example RSS 2.0 feed
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/rss-20.xml
  - module: Filter::ExtractAuthorName
--- expected
is $context->update->feeds->[0]->author, 'Dave Winer';
is $context->update->feeds->[0]->entries->[0]->author, 'Dave Winer';

=== Flickr 2.0 feed
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - http://www.flickr.com/services/feeds/photos_public.gne?id=49503048699@N01&format=rss_200
  - module: Filter::ExtractAuthorName
--- expected
is $context->update->feeds->[0]->entries->[0]->author, 'miyagawa';
