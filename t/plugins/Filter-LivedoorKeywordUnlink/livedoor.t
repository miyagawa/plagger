use strict;
use Test::More skip_all => "their keyword link feature is now disabled.";

use Plagger;

# catch log output
my $log;
{ local $SIG{__WARN__} = sub { $log .= "@_" };

  Plagger->bootstrap(config => \<<'CONFIG');
global:
  log:
    level: info
plugins:
  - module: Subscription::Config
    config:
      feed:
        - http://blog.livedoor.jp/staff/atom.xml

  - module: Filter::LivedoorKeywordUnlink
CONFIG
}

like $log, qr/Stripped \d+ links to Livedoor Keyword/;

