use strict;
use FindBin;
use File::Spec;
use t::TestPlagger;
use XML::Feed;

our $output = "$FindBin::Bin/atom.xml";

test_plugin_deps;
plan 'no_plan';
run_eval_expected;

END {
    unlink $output if -e $output;
}

__END__

=== Atom 1.0 without category
--- input config output_file
plugins:
  - module: CustomFeed::Debug
    config:
      title: Foo
      entry:
        - title: bar
          link: http://www.example.org/
  - module: Publish::Feed
    config:
      dir: $FindBin::Bin
      filename: atom.xml
--- expected
file_doesnt_contain($main::output, qr/<category/);

