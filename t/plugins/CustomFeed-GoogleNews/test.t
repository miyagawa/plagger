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
        - http://news.google.com/news?ned=jp&rec=0&topic=s
        - http://news.google.co.jp/news?hl=ja&ned=tjp&q=%E5%9B%B2%E7%A2%81&ie=UTF-8&scoring=d

  - module: CustomFeed::GoogleNews
  - module: Filter::Test
CONFIG

package Plagger::Plugin::Filter::Test;
use base qw( Plagger::Plugin );

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'update.feed.fixup' => \&feed,
    );
}

sub feed {
    my($self, $context, $args) = @_;
    ::ok $args->{feed}->count;
}
