use strict;
use t::TestPlagger;

test_requires_network;
test_plugin_deps;
plan tests => 6;

run_eval_expected;

__END__

=== Test Flickr Contact Photos
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/flickr-friends.xml
  - module: Filter::FlickrContactPhotos
    config:
     api_key: 9d58b60bd3cb21e7d5cd940f3f7c7305
--- expected
is $context->update->feeds->[0]->entries->[0]->icon->{url},   'http://farm1.static.flickr.com/25/buddyicons/61554089@N00.jpg';
is $context->update->feeds->[0]->entries->[0]->icon->{title}, 'Natsu Tohi';
is $context->update->feeds->[0]->entries->[0]->icon->{link},  'http://www.flickr.com/people/tohinatsu/';
is $context->update->feeds->[0]->entries->[1]->icon->{url},   'http://farm1.static.flickr.com/5/buddyicons/26153219@N00.jpg';
is $context->update->feeds->[0]->entries->[1]->icon->{title}, 'Kohichi Aoki';
is $context->update->feeds->[0]->entries->[1]->icon->{link},  'http://www.flickr.com/people/drikin/';
