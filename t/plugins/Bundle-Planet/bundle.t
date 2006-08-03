use strict;
use FindBin;
use File::Path;
use t::TestPlagger;

test_requires_network;
test_plugin_deps;

plan 'no_plan';

our $dir    = "$FindBin::Bin/planet";
our $output = "$dir/index.html";

run_eval_expected;

END {
    rmtree $dir if $dir && -e $dir;
}

__END__

=== Test bundle
--- input config
global:
  log:
    level: error
  assets_path: $FindBin::Bin/../../../assets
plugins:
  - module: Subscription::Config
    config:
      feed:
        - http://blog.bulknews.net/mt/index.rdf
        - http://subtech.g.hatena.ne.jp/miyagawa/rss
  - module: Bundle::Planet
    config:
      dir: $main::dir
      title: Planet Foobar
      url: http://planet.plagger.org/
      theme: sixapart-std
      stylesheet: foo.css
--- expected
ok -e "$main::dir/index.html";
ok -e "$main::dir/rss.xml";
ok -e "$main::dir/atom.xml";
file_contains("$main::dir/index.html", qr(href="http://planet.plagger.org/atom.xml"));
file_contains("$main::dir/index.html", qr(href="http://planet.plagger.org/rss.xml"));
file_contains("$main::dir/index.html", qr(href="http://planet.plagger.org/foo.css"));
file_contains("$main::dir/index.html", qr(href="http://planet.plagger.org/subscriptions.opml"));
file_contains("$main::dir/index.html", qr(href="http://planet.plagger.org/foafroll.xml"));
file_contains("$main::dir/atom.xml", qr!href="http://planet.plagger.org/"!);
file_contains("$main::dir/rss.xml", qr!<link>http://planet.plagger.org/</link>!);
file_contains("$main::dir/subscriptions.opml", qr!<head>\s*<title>Planet Foobar</title>!);
file_contains("$main::dir/subscriptions.opml", qr!<outline title="blog.bulknews.net"!);
file_contains("$main::dir/subscriptions.opml", qr!<outline title="Bulknews::Subtech"!);
file_doesnt_contain("$main::dir/subscriptions.opml", qr!<outline title="Planet Foobar"!);
file_contains("$main::dir/foafroll.xml", qr!<foaf:name>Planet Foobar!);
file_contains("$main::dir/foafroll.xml", qr!<foaf:homepage>http://planet.plagger.org/!);
file_contains("$main::dir/foafroll.xml", qr!<rdfs:seeAlso rdf:resource="http://planet.plagger.org/foafroll.xml" />!);

=== Test bundle
--- input config
global:
  log:
    level: error
  assets_path: $FindBin::Bin/../../../assets
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$FindBin::Bin/../../samples/tags-in-title.xml
  - module: Bundle::Planet
    config:
      dir: $main::dir
      title: Planet Foobar
      url: http://planet.plagger.org/
--- expected
file_contains("$main::dir/index.html", qr/Plagger rocks/);
file_contains("$main::dir/atom.xml", qr/Plagger rocks/);
