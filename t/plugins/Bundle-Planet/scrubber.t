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
global:
  log:
    level: error
  assets_path: $FindBin::Bin/../../../assets
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file:///$FindBin::Bin/../../samples/nasty.xml
  - module: Bundle::Planet
    config:
      dir: $main::dir
      title: Planet Foobar
      url: http://planet.plagger.org/
      theme: sixapart-std
      stylesheet: foo.css
      duration: 3 years
--- expected
like $block->input, qr!<p>foo bar <a href="foo\.html">baz</a></p>!;
unlike $block->input, qr!<script>!;
unlike $block->input, qr!onclick=!;
unlike $block->input, qr!<style>blah blah</style>!;

=== allow style attribute
--- input config output_file
global:
  log:
    level: error
  assets_path: $FindBin::Bin/../../../assets
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file:///$FindBin::Bin/../../samples/nasty.xml
  - module: Bundle::Planet
    config:
      title: Foo
      dir: $main::dir
      url: http://plagger.org/
      theme: sixapart-std
      scrubber:
        default:
          style: 1
      duration: 3 years
--- expected
like $block->input, qr!<p>foo bar <a href="foo\.html">baz</a></p>!;
unlike $block->input, qr!<script>!;
unlike $block->input, qr!onclick=!;
unlike $block->input, qr!<style>blah blah</style>!;
like $block->input, qr!<div style="font-size: foo">foo</div>!;
