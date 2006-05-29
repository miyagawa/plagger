use strict;
use Test::More tests => 6;
use FindBin;

use Plagger;

# cookies: filename
Plagger->bootstrap(config => \<<CONFIG);
global:
  log:
    level: error
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$FindBin::Bin/monkey.rss
        - file://$FindBin::Bin/googlevideo.xml
  - module: Test::MediaRSS
CONFIG

package Plagger::Plugin::Test::MediaRSS;
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

    ::is( ($feeds[0]->entries)[0]->enclosures->[0]->url, 'http://youtube.com/v/MgldehkjK5k.swf' );
    ::is( ($feeds[0]->entries)[0]->enclosures->[0]->type, 'application/x-shockwave-flash' );
    ::is( ($feeds[0]->entries)[0]->icon->{url}, 'http://sjl-static4.sjl.youtube.com/vi/MgldehkjK5k/2.jpg' );

    ::is( ($feeds[1]->entries)[0]->enclosures->[0]->type, 'video/mp4' );
    ::is( ($feeds[1]->entries)[0]->enclosures->[1]->type, 'video/x-flv' );

    ::is( ($feeds[1]->entries)[0]->icon->{url}, 'http://video.google.com/ThumbnailServer?app=vss&contentid=ac22092b58659308&second=5&itag=w320&urlcreated=1148908032&sigh=oxDLuV7bChBhYFMFSFamVpkIHHE' );
}

