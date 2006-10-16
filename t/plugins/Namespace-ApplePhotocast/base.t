use strict;
use FindBin;
use t::TestPlagger;

test_plugin_deps('Filter::RSSLiberalDateTime');

plan tests => 3;
run_eval_expected;

__END__

=== Photocast
--- input config
global:
  log:
    level: error
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/photocast.rss
  # OMG Apple Photocast has invalida pubDate formats ... fix it.
  - module: Filter::RSSLiberalDateTime
--- expected
my @feeds = $context->update->feeds;
is $feeds[0]->entries->[0]->enclosures->[0]->url, 'http://web.mac.com/mrakes/iPhoto/photocast_test/1C8C5C8D-651D-4990-B6DD-DF11D515213C.jpg';
is $feeds[0]->entries->[0]->enclosures->[0]->type, 'image/jpeg';
is $feeds[0]->entries->[0]->icon->{url}, 'http://web.mac.com/mrakes/iPhoto/photocast_test/1C8C5C8D-651D-4990-B6DD-DF11D515213C.jpg?transform=medium';


