use strict;
use FindBin;
use File::Spec;
use t::TestPlagger;
use XML::Feed;

our $output = "$FindBin::Bin/atom.xml";

test_plugin_deps;
plan tests => 2;
run_eval_expected;

END {
    unlink $output if -e $output;
}

__END__

=== Atom 1.0 generation
--- input config output_file
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/rss-full.xml
  - module: Publish::Feed
    config:
      format: Atom
      dir: $FindBin::Bin
      filename: atom.xml
--- expected
my $feed = XML::Atom::Feed->new($main::output);
is $feed->version, '1.0';
is $feed->title, 'Bulknews::Subtech';


