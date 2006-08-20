use strict;
use t::TestPlagger;
use FindBin;
use File::Path;

test_plugin_deps;

our $output = "$FindBin::Bin/tmp/index.html";

mkpath "$FindBin::Bin/tmp";

plan 'no_plan';
run_eval_expected;

END {
     unlink $output if $output && -e $output;
     rmtree "$FindBin::Bin/tmp";
}

__END__

=== PDF
--- input config output_file
global:
   assets_path: $t::TestPlagger::BaseDir/assets
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/rss2sample.xml
  - module: Publish::CHTML
    config:
      work: $FindBin::Bin/tmp
--- expected
file_contains($main::output, qr{<!DOCTYPE HTML PUBLIC "-//W3C//DTD Compact HTML 1.0 Draft//EN">});
