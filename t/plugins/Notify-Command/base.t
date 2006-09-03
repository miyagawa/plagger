use strict;
use t::TestPlagger;

our $file = "$t::TestPlagger::BaseDir/bazbaareiabraira";

# echo is actually a shell built-in, but it fails on Win32 which is okay
test_requires_command 'echo';

test_plugin_deps;
plan 'no_plan';
run_eval_expected;

END {
    unlink $file if -e $file;
}

__END__

=== Loading Notify::Command
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/rss-full.xml
  - module: Notify::Command
    config:
      command: echo "foo" > $main::file
--- expected
ok -e $main::file;
file_contains($main::file, qr/foo/);
