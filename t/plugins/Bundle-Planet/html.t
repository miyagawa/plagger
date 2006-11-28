use strict;
use FindBin;
use File::Path;
use t::TestPlagger;

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
--- input config output_file
plugins:
  - module: CustomFeed::Debug
    config:
      title: Feed: Foo & Bar
      url: http://www.example.com/rss
      link: http://www.example.com/
      entry:
        - title: <p>Entry: Foo &amp; Bar</p>
          body: Foo <x><script>foo</script><y> bar
          date: 2006/10/11 00:00:00 GMT
          link: http://www.example.com/2
        - title: doodle
          body: Body: foo & bar
          date: 2006/10/11 00:00:00 GMT
          link: http://www.example.com/1
  - module: Bundle::Planet
    config:
      dir: $main::dir
      title: Planet Foobar
      url: http://planet.plagger.org/
      theme: sixapart-std
      stylesheet: foo.css
      duration: 10 years
--- expected
like $block->input, qr!<a href="http://www.example.com/">Feed: Foo &amp; Bar</a>!;
like $block->input, qr!<a href="http://www.example.com/2">Entry: Foo &amp; Bar</a>!;
like $block->input, qr!Foo &lt;x&gt;&lt;script&gt;foo&lt;/script&gt;&lt;y&gt; bar!;
like $block->input, qr!Body: foo &amp; bar!;


