use strict;
use FindBin;

use t::TestPlagger;

plan tests => 6;
run_eval_expected;

__END__

=== Media RSS
--- input config 
global:
  log:
    level: error
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/monkey.rss
        - file://$t::TestPlagger::BaseDirURI/t/samples/googlevideo.xml
--- expected
my @feeds = $context->update->feeds;

is( ($feeds[0]->entries)[0]->enclosures->[0]->url, 'http://youtube.com/v/MgldehkjK5k.swf' );
is( ($feeds[0]->entries)[0]->enclosures->[0]->type, 'application/x-shockwave-flash' );
is( ($feeds[0]->entries)[0]->icon->{url}, 'http://sjl-static4.sjl.youtube.com/vi/MgldehkjK5k/2.jpg' );
is( ($feeds[1]->entries)[0]->enclosures->[0]->type, 'video/mp4' );
is( ($feeds[1]->entries)[0]->enclosures->[1]->type, 'video/x-flv' );
is( ($feeds[1]->entries)[0]->icon->{url}, 'http://video.google.com/ThumbnailServer?app=vss&contentid=ac22092b58659308&second=5&itag=w320&urlcreated=1148908032&sigh=oxDLuV7bChBhYFMFSFamVpkIHHE' );


