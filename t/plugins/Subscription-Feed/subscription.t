use strict;
use FindBin;
use File::Spec;
use Test::More tests => 2;

use Plagger;
Plagger->bootstrap(config => \<<CONFIG);
global:
  log:
    level: error
plugins:
  - module: Subscription::Feed
    config:
      url: file:///$FindBin::Bin/feed.xml
  - module: Aggregator::Test
CONFIG

package Plagger::Plugin::Aggregator::Test;
use base qw( Plagger::Plugin );

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'customfeed.handle' => \&load,
        'aggregator.finalize' => \&test,
    );
}

sub load {
    my($self, $context, $args) = @_;
    push @{$self->{feeds}}, $args->{feed}->url;
    return 1;
}

sub test {
    my($self, $context) = @_;
    ::is $self->{feeds}->[0], "http://d.hatena.ne.jp/agw/20060526/1148633449#c";
    ::is $self->{feeds}->[1], "http://d.hatena.ne.jp/nirvash/20060517/1147836803#c";
}

