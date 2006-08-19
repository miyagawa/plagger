use strict;
use FindBin;
use t::TestPlagger;
use File::Spec;

our $output = File::Spec->rel2abs("$FindBin::Bin/test.pps");

test_plugin_deps;
plan 'no_plan';
run_eval_expected;

END {
    unlink $output if -e $output;
}

__END__

=== PowerPoint
--- input config output_file
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file:///$FindBin::Bin/../../samples/rss-full.xml
  - module: Publish::PowerPoint
    config:
      dir: $FindBin::Bin
      filename: test.pps
--- expected
ok -f $main::output;
ok -s $main::output > 1024;
