use strict;
use FindBin;
use File::Spec;
use t::TestPlagger;

our $url = "file:///$FindBin::Bin/../../samples/rss-full.xml";
our $dir = $FindBin::Bin;

test_plugin_deps;
plan 'no_plan';
run_eval_expected;

END {
    for my $file (glob(File::Spec->catfile($main::dir, '*.webbookmark'))) {
    	unlink $file;
    }
}

__END__

=== Test
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - $main::url
  - module: Search::Spotlight
    config:
      dir: $main::dir
--- expected
my @files = glob(File::Spec->catfile($main::dir, '*.webbookmark'));
is 5, @files;
for my $file (@files) {
    file_contains($file, qr/<plist version="1.0">/);
}

