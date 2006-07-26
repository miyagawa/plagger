use strict;
use FindBin;
use t::TestPlagger;

plan tests => 2;
run_eval_expected;

__END__

=== Test 1
--- input config
global:
  assets_path: $FindBin::Bin/../../../assets
  log:
    level: error
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
--- expected
is $context->update->feeds->[0]->entries->[0]->enclosure->url, 'http://www.youtube.com/v/nqAWmQ8cdWw';
is $context->update->feeds->[0]->entries->[1]->enclosure->url, 'https://hatena.g.hatena.ne.jp/files/hatena/b9f904875fcd5333.flv';
