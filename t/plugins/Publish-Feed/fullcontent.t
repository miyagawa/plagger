use strict;
use FindBin;
use File::Spec;
use t::TestPlagger;
use XML::Feed;

our $output = "$FindBin::Bin/rss.xml";

test_plugin_deps;
plan tests => 2;
run_eval_expected;

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
      full_content: 0
--- expected
file_doesnt_contain($main::output, qr/&lt;a href=/);
file_contains($main::output, qr/for\s+(\*\s*)?http/s);

