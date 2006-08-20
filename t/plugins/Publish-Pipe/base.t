use strict;
use FindBin;
use File::Spec;
use t::TestPlagger;

our $url = "file://$t::TestPlagger::BaseDirURI/t/samples/rss-full.xml";
our $output = $FindBin::Bin . "/output.txt";

test_requires_command 'sed';
plan 'no_plan';
run_eval_expected;

END {
    unlink $output if $output && -e $output;
}

__END__

=== Test
--- input config output_file
plugins:
  - module: Subscription::Config
    config:
      feed:
        - $main::url
  - module: Publish::Pipe
    config:
      command: sed 's/Plagger/Plaggger/g' > $main::output
--- expected
file_contains($main::output, qr/Plaggger/);
