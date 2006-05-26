use strict;
use Test::More tests => 1;

use Plagger;

my $log;
{ local $SIG{__WARN__} = sub { $log .= "@_" };
  Plagger->bootstrap(config => \<<'CONFIG');
global:
  log:
#    level: error
plugins:
  - module: Subscription::Config
    config:
      feed:
        - http://www.sixapart.com/pronet/weblog/

  - module: Filter::FeedBurnerPermalink
CONFIG
}

like $log, qr/Permalink rewritten to/;
