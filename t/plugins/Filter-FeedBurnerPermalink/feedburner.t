use strict;
use Test::More tests => 2;

use Plagger;

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
