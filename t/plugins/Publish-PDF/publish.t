use strict;
use t::TestPlagger;
use FindBin;

our $output;

test_plugin_deps;
plan 'no_plan';
run_eval_expected;

END {
    unlink $output if $output && -e $output;
}

__END__

=== PDF
--- input config 
global:
   assets_path: $t::TestPlagger::BaseDir/assets
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/rss2sample.xml
  - module: Publish::PDF
    config:
      dir: $FindBin::Bin
--- expected
ok $main::output = glob "$FindBin::Bin/*.pdf";
ok -f $main::output;
ok -s $main::output > 3000;
file_contains($main::output, qr/\x25\x50\x44\x46\x2D\x31\x2E/);
