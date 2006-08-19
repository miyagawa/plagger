use strict;
use t::TestPlagger;

our $url    = "file://$t::TestPlagger::BaseDirURI/t/samples/rss-full.xml";
our $output = $FindBin::Bin . "/" . Digest::MD5::md5_hex($url) . ".json";

test_plugin_deps;
plan 'no_plan';
run_eval_expected;

END {
    unlink $output if $output && -e $output;
}

__END__

=== Dump feed to JSON
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - $main::url
  - module: Publish::JSON
    config:
      dir: $FindBin::Bin
--- expected
file_contains($main::output, qr/"date":"2006-07-04T23:48:22\+09:00"/);

=== Dump feed to JSON using varname
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - $main::url
  - module: Publish::JSON
    config:
      dir: $FindBin::Bin
      varname: foo
--- expected
file_contains($main::output, qr/var foo = /);

=== Dump feed to JSON using JSONP
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - $main::url
  - module: Publish::JSON
    config:
      dir: $FindBin::Bin
      jsonp: callback
--- expected
file_contains($main::output, qr/^callback\(/);

