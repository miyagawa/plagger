use strict;
use t::TestPlagger;
use FindBin;

our $output = "$FindBin::Bin/test-rss2sample.xls";

test_plugin_deps;
plan 'no_plan';
run_eval_expected;

END {
    unlink $output if $output && -e $output;
}

__END__

=== PowerPoint
--- input config output_file
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/rss2sample.xml
  - module: Publish::Excel
    config:
      filename: $main::output
--- expected
ok -f $main::output;
ok -s $main::output > 3000;
file_contains($main::output, qr/\xD0\xCF\x11\xE0\xA1\xB1\x1A\xE1\x00/);
file_contains($main::output, qr/Tue, 03 Jun 2003 09:39:21/);
