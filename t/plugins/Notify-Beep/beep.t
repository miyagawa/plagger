use strict;
use t::TestPlagger;
use FindBin;
 
test_requires 'Audio::Beep';
{
    no warnings qw(once redefine);
    *Audio::Beep::beep = \&beep_ok;
    sub beep_ok { warn 'beep ok' }
}
 
plan tests => 1;
 
run_eval_expected_with_capture;
 
__END__
 
=== test file
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/rss2sample.xml
  - module: Notify::Beep
--- expected
like $warnings, qr/beep ok/;
