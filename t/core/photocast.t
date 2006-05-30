use strict;
use Test::More tests => 3;
use FindBin;

use Plagger;

Plagger->bootstrap(config => \<<CONFIG);
global:
  log:
    level: error
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$FindBin::Bin/photocast.rss
  # OMG Apple Photocast has invalida pubDate formats ... fix it.
  - module: Filter::RSSLiberalDateTime
  - module: Test::Photocast
CONFIG

package Plagger::Plugin::Test::Photocast;
use base qw( Plagger::Plugin );

sub register {
    my($self, $context) = @_;

    $context->register_hook(
        $self,
        'aggregator.finalize' => \&test,
    );
}

sub test {
    my($self, $context, $args) = @_;

    my @feeds = $context->update->feeds;

    ::is( ($feeds[0]->entries)[0]->enclosures->[0]->url, 'http://web.mac.com/mrakes/iPhoto/photocast_test/1C8C5C8D-651D-4990-B6DD-DF11D515213C.jpg' );
    ::is( ($feeds[0]->entries)[0]->enclosures->[0]->type, 'image/jpeg' );
    ::is( ($feeds[0]->entries)[0]->icon->{url}, 'http://web.mac.com/mrakes/iPhoto/photocast_test/1C8C5C8D-651D-4990-B6DD-DF11D515213C.jpg?transform=medium' );
}

