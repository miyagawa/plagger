use strict;
use t::TestPlagger;
use FindBin;
 
test_requires 'Audio::Beep';
{
    no warnings qw(once redefine);
    *Audio::Beep::play = \&music_ok;
    sub music_ok { warn $_[1] }
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
    config:
      music: "g' f bes' c8 f d4 c8 f d4 bes c g f2"
--- expected
like $warnings, qr/g' f bes' c8 f d4 c8 f d4 bes c g f2/;
