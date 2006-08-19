use strict;
use t::TestPlagger;

our $url    = "file://$t::TestPlagger::BaseDirURI/t/samples/rss-full.xml";
our $output = $FindBin::Bin . "/plagger_test.csv";

test_plugin_deps;
plan 'no_plan';
run_eval_expected;

END {
    unlink $output if $output && -e $output;
}

__END__

=== feed to CSV
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - $main::url

  - module: Publish::CSV
    config:
      dir: $FindBin::Bin
      encoding: utf-8
      filename: plagger_test.csv
      mode: append
      column:
       - title
       - permalink
--- expected
file_contains($main::output, qr/" Gmail",http:\/\/subtech.g.hatena.ne.jp\/miyagawa\/20060704\/1152024502/);
