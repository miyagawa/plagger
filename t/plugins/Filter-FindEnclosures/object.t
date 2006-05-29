use strict;
use FindBin;
use Test::More tests => 2;

use Plagger;

my $log;
{ local $SIG{__WARN__} = sub { $log .=  "@_" };
  Plagger->bootstrap(config => \<<"CONFIG");
global:
  assets_path: $FindBin::Bin/../../../assets
  log:
    level: debug
plugins:
  - module: CustomFeed::Debug
    config:
      title: Test
      link: http://example.com/
      entry:
        - title: Test 1
          link: http://bulknews.typepad.com/
          body: |
            Here's a link to YouTube. <object width="425" height="350"><param name="movie" value="http://www.youtube.com/v/nqAWmQ8cdWw"></param><embed src="http://www.youtube.com/v/nqAWmQ8cdWw" type="application/x-shockwave-flash" width="425" height="350"></embed></object>
        - title: Test 2
          link: http://d.hatena.ne.jp/miyagawa/
          body: >
            Here's a link to Hatena. <object classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000" codebase="http://fpdownload.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=8,0,0,0" width="320" height="205" id="flvplayer" align="middle">
            <param name="allowScriptAccess" value="sameDomain" />
            <param name="movie" value="http://g.hatena.ne.jp/tools/flvplayer.swf" />
            <param name="quality" value="high" />
            <param name="bgcolor" value="#ffffff" />
            <param name="FlashVars" value="moviePath=https://hatena.g.hatena.ne.jp/files/hatena/b9f904875fcd5333.flv" />
            <embed src="http://g.hatena.ne.jp/tools/flvplayer.swf" FlashVars="moviePath=https://hatena.g.hatena.ne.jp/files/hatena/b9f904875fcd5333.flv" quality="high" bgcolor="#ffffff" width="320" height="205" name="flvplayer" align="middle" allowScriptAccess="sameDomain" type="application/x-shockwave-flash" pluginspage="http://www.macromedia.com/go/getflashplayer" />
            </object>

  - module: Filter::FindEnclosures
CONFIG
}

like $log, qr!Found enclosure http://www\.youtube\.com/v/nqAWmQ8cdWw!;
like $log, qr!Found enclosure https://hatena\.g\.hatena\.ne\.jp/files/hatena/b9f904875fcd5333\.flv!;
