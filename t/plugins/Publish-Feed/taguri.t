use strict;
use FindBin;
use File::Spec;
use t::TestPlagger;
use XML::Feed;
use Sys::Hostname;

our $output = "$FindBin::Bin/atom.xml";
our $hostname = Sys::Hostname::hostname;

test_plugin_deps;
plan 'no_plan';
run_eval_expected;

END {
    unlink $output if -e $output;
}

__END__

=== TagURI with config
--- input config output_file
plugins:
  - module: CustomFeed::Debug
    config:
      title: Foo
      author: miyagawa
      entry:
        - title: bar
          link: http://www.example.org/
  - module: Publish::Feed
    config:
      dir: $FindBin::Bin
      filename: atom.xml
      taguri_base: example.com
--- expected
file_doesnt_contain($main::output, qr/tag:plagger\.org/);
file_contains($main::output, qr/tag:example\.com/);

=== TagURI with default hostname
--- input config output_file
plugins:
  - module: CustomFeed::Debug
    config:
      title: Foo
      author: miyagawa
      entry:
        - title: bar
          link: http://www.example.org/
  - module: Publish::Feed
    config:
      dir: $FindBin::Bin
      filename: atom.xml
--- expected
file_doesnt_contain($main::output, qr/tag:plagger\.org/);
file_contains($main::output, qr/tag:$main::hostname/);










