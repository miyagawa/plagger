use strict;
use FindBin;
use File::Spec;
use t::TestPlagger;

test_plugin_deps;

use Digest::MD5;

our $url = "file://$t::TestPlagger::BaseDirURI/t/samples/rss-full.xml";
our $output = $FindBin::Bin . "/" . Digest::MD5::md5_hex($url) . ".js";

run_like 'input' => 'expected';

END {
    unlink $output if $output && -e $output;
}

__END__

=== Test
--- input config output_file
plugins:
  - module: Subscription::Config
    config:
      feed:
        - $main::url
  - module: Publish::JavaScript
    config:
      dir: $FindBin::Bin
--- expected chomp regexp
document\.write
