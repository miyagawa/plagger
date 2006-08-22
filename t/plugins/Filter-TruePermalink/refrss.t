use strict;
use t::TestPlagger;

plan 'no_plan';
run_eval_expected;

__END__

=== 
--- input config
plugins:
  - module: CustomFeed::Debug
    config:
      title: Foo
      entry:
        - link: http://blogs.itmedia.co.jp/serial/2006/08/2_f80e.html?ref=rssall
        - link: http://blogs.itmedia.co.jp/serial/2006/08/2_f80e.html?ref=rss&foo=bar
        - link: http://blogs.itmedia.co.jp/serial/2006/08/2_f80e.html?foo=bar;ref=rss
        - link: http://blogs.itmedia.co.jp/serial/2006/08/2_f80e.html?ref=rss;foo=bar
        - link: http://blogs.itmedia.co.jp/serial/2006/08/2_f80e.html?foo=bar&ref=rss
        - link: http://blogs.itmedia.co.jp/serial/2006/08/2_f80e.html?ref=rss
        - link: http://blogs.itmedia.co.jp/serial/2006/08/2_f80e.html?rss
  - module: Filter::TruePermalink
--- expected
for my $e ($context->update->feeds->[0]->entries) {
    unlike $e->permalink, qr/rss/;
}


