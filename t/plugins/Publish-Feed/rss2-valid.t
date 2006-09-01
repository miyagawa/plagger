use strict;
use t::TestPlagger;

test_plugin_deps;

unless (-e "$ENV{HOME}/svn/feedvalidator") {
    plan skip_all => "You need to checkout feedvalidator in $ENV{HOME}/svn to run this test";
}

our $output = "$FindBin::Bin/rss.xml";

plan 'no_plan';
run_eval_expected;

END {
    unlink $output if $output && -e $output;
}

__END__

=== RSS 2.0 validation
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
--- expected
local $ENV{LANGUAGE} = 'en';
my $out = `$ENV{HOME}/svn/feedvalidator/src/demo.py $main::output A`;
like $out, qr/No errors or warnings/;
