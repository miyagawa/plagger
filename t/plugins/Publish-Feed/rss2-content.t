use strict;
use FindBin;
use File::Spec;
use t::TestPlagger;
use XML::Feed;

test_plugin_deps;

our $output = "$FindBin::Bin/rss.xml";
run_like 'input', 'expected';

END {
    unlink $output if -e $output;
}

__END__

=== RSS 2.0 config
--- input config output_file
global:
  log:
    level: error
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file:///$FindBin::Bin/../../samples/rss-full.xml
  - module: Publish::Feed
    config:
      format: RSS
      dir: $FindBin::Bin
      filename: rss.xml
--- expected chomp regexp
<content:encoded>\s*&lt;div
