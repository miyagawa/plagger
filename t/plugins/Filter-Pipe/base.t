use strict;
use t::TestPlagger;
use File::Spec;

test_plugin_deps;
test_requires_command('tee');
test_requires('Encode::Detect::Detector');

our $tmp = File::Spec->catdir($ENV{TEMP} || $ENV{TMP} || '/tmp',  $$ . time);

plan 'no_plan';
run_eval_expected_with_capture;

__END__

=== Loading Filter::Pipe
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/rss-full.xml

  - module: Filter::Pipe
    config:
      command: tee -a $main::tmp
      encoding: euc-jp
--- expected
ok -f $main::tmp;
undef $/;
open FH, $main::tmp;
is Encode::Detect::Detector::detect(<FH>), 'EUC-JP';
close FH;
unlink $main::tmp;

=== Loading Filter::Pipe
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/rss-full.xml

  - module: Filter::Pipe
    config:
      command: tee -a $main::tmp
      encoding: utf8
      text_only: 1
--- expected
ok -f $main::tmp;
undef $/;
open FH, $main::tmp;
ok <FH> !~ m!</?\w+>!;
close FH;
unlink $main::tmp;

=== Testing buffered output
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/rss-full.xml

  - module: Filter::Pipe
    config:
      command: ruby -e 'print \$stdin.read'
      encoding: utf8
      text_only: 1
--- expected
unlike $warnings, qr/timeout/, "no timeout";

