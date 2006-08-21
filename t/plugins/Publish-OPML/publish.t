use strict;
use t::TestPlagger;
use FindBin;

our $output = "$FindBin::Bin/subscription.opml";

plan 'no_plan';
run_eval_expected;

END {
     unlink $output if $output && -e $output;
}

__END__

=== PDF
--- input config output_file
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/rss2sample.xml
  - module: Publish::OPML
    config:
      filename: $main::output
--- expected
file_contains($main::output, qr{<opml version="1.0">});
file_contains($main::output, qr{<outline title=".*" htmlUrl=".*" text=".*" type=".*" xmlUrl=".*" />});

