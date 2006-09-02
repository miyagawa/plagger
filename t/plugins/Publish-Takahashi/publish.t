use strict;
use FindBin;
use t::TestPlagger;
use File::Spec;
use Digest::MD5 qw(md5_hex);

our $url = "file://$t::TestPlagger::BaseDirURI/t/samples/rss-full.xml";
my $id = md5_hex($url);

our $output = File::Spec->rel2abs("$FindBin::Bin/$id.xul");
our $css    = File::Spec->rel2abs("$FindBin::Bin/takahashi.css");
our $js     = File::Spec->rel2abs("$FindBin::Bin/takahashi.js");

test_plugin_deps;
plan 'no_plan';
run_eval_expected;

END {
    unlink $output if -e $output;
    unlink $css    if -e $css;
    unlink $js     if -e $js;
}

__END__

=== Takahashi
--- input config output_file
plugins:
  - module: Subscription::Config
    config:
      feed:
        - $main::url
  - module: Publish::Takahashi
    config:
      dir: $FindBin::Bin
--- expected

# check the file exists
ok -f $main::output;
ok -s $main::output > 1024;

# check that the file contents matches
file_contains($main::output, qr/Consolas/);

# check we also included the takahashi files
ok -f $main::css;
ok -f $main::js;
