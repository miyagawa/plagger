use strict;
use t::TestPlagger;
use FindBin;

our $output = "$FindBin::Bin/subscription.txt";

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

  - module: Publish::OutlineText
    config:
      filename: $main::output
      encoding: utf8

--- expected
file_contains($main::output, qr{.Liftoff News});
file_contains($main::output, qr{..Star City});
file_contains($main::output, qr{..The Engine That Does More});
file_contains($main::output, qr{..Astronauts' Dirty Laundry});
