use strict;
use t::TestPlagger;
use FindBin;

test_requires 'Win32::MCI::Basic' if ($^O eq 'MSWin32');

test_requires 'Plagger::Plugin::Notify::Eject';
{
    no warnings 'once';
    *CORE::GLOBAL::system = \&eject_ok; 
    *Win32::MCI::Basic::mciSendString = \&eject_ok;
    sub eject_ok { warn 'eject ok' }
}

plan tests => 1;

run_eval_expected_with_capture;

__END__

=== test file
--- input config
global:
  log:
    level: debug
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$FindBin::Bin/../../samples/rss2sample.xml
  - module: Notify::Eject
--- expected
like $warning, qr/eject ok/;

