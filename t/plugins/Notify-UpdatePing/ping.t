use strict;
use FindBin;
use File::Spec;
use Test::More tests => 3;

use Plagger;

no warnings 'redefine';
local *XMLRPC::Lite::call = sub {
    my($self, $method, $name, $url) = @_;
    is $method, 'weblogUpdates.ping';
    is $name->value, 'blog.bulknews.net';
    is $url, 'http://blog.bulknews.net/mt/';
};

Plagger->bootstrap(config => \<<CONFIG);
global:
  log:
    level: error
plugins:
  - module: Subscription::Config
    config:
      feed:
        - http://blog.bulknews.net/mt/
  - module: Notify::UpdatePing
    config:
      url: http://localhost/ping
CONFIG

