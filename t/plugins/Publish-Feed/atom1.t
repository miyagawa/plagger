use strict;
use FindBin;
use File::Spec;
use t::TestPlagger;
use XML::Feed;

test_plugin_deps;

our $output = "$FindBin::Bin/atom.xml";

plan tests => 2;
run_eval_expected;

END {
    unlink $output if -e $output;
}

__END__

=== Atom 1.0 generation
--- input config output_file
global:
  log:
    level: error
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file:///$FindBin::Bin/../../samples/rss-full.xml
  - module: Publish::Feed
    config:
      format: Atom
      dir: $FindBin::Bin
      filename: atom.xml
--- expected
my $feed = XML::Atom::Feed->new($main::output);
is $feed->version, '1.0';
is $feed->title, 'Bulknews::Subtech';


