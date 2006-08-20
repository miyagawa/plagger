use strict;
use FindBin;
use File::Spec;
use t::TestPlagger;
use XML::Feed;

our $output = "$FindBin::Bin/rss.xml";

test_plugin_deps;
run_like 'input', 'expected';

END {
    unlink $output if -e $output;
}

__END__

=== RSS 2.0 config
--- input config output_file
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/rss-full.xml
  - module: Publish::Feed
    config:
      format: RSS
      dir: $FindBin::Bin
      filename: rss.xml
--- expected chomp regexp
<content:encoded>\s*&lt;div
