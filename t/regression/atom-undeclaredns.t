use strict;
use warnings;
use FindBin;
use t::TestPlagger;

plan 'no_plan';

our $output = "$FindBin::Bin/atom.xml";
run_like 'input', 'expected';

END { unlink $output }

__END__
=== vox.com
--- input config output_file
global:
  log:
    level: error
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/vox.xml
  - module: Publish::Feed
    config:
      dir: $FindBin::Bin
      filename: atom.xml
--- expected regexp
vox
