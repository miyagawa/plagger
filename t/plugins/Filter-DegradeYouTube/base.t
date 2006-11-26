use strict;
use t::TestPlagger;

test_plugin_deps;
plan 'no_plan';
run_eval_expected;

__END__

=== Loading Filter::DegradeYouTube
--- input config
plugins:
  - module: Filter::DegradeYouTube
--- expected
ok 1, $block->name;

=== no dev_id
--- input config
plugins:
  - module: Filter::DegradeYouTube

  - module: CustomFeed::Debug
    config:
      title: feed title
      entry:
        - title: frepa
          link: http://www.frepa.livedoor.com/blog/show?id=4&diary=60231
          body: <object width="340" height="280"><param name="movie" value="http://www.youtube.com/v/nf8LyHLN2x4"></param><param name="wmode" value="transparent"></param><embed src="http://www.youtube.com/v/nf8LyHLN2x4"  type="application/x-shockwave-flash" wmode="transparent"  width="340" height="280"></embed></object>
--- expected
like $context->update->feeds->[0]->entries->[0]->body, qr{<a href="http://www.youtube.com/v/nf8LyHLN2x4">YouTube Movie</a>}, "degrade with no dev_id";

=== with dev_id
--- input config
plugins:
  - module: Filter::DegradeYouTube
    config:
      dev_id: DkL0TIF7LpQ

  - module: CustomFeed::Debug
    config:
      title: feed title
      entry:
        - title: frepa
          link: http://www.frepa.livedoor.com/blog/show?id=4&diary=60231
          body: <object width="340" height="280"><param name="movie" value="http://www.youtube.com/v/nf8LyHLN2x4"></param><param name="wmode" value="transparent"></param><embed src="http://www.youtube.com/v/nf8LyHLN2x4"  type="application/x-shockwave-flash" wmode="transparent"  width="340" height="280"></embed></object>
--- expected
like $context->update->feeds->[0]->entries->[0]->body, qr{<a href="http://www.youtube.com/v/nf8LyHLN2x4"><img src="http://sjl-static16.sjl.youtube.com/vi/nf8LyHLN2x4/2.jpg" /></a>}, "degrade with thumbnail";
