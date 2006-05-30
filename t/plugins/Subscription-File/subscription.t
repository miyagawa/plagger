use strict;
use FindBin;
use File::Spec;
use Test::More tests => 1;

use Plagger;
Plagger->bootstrap(config => \<<CONFIG);
global:
  log:
    level: error
plugins:
  - module: Subscription::File
    config:
      file: $FindBin::Bin/feeds.txt
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
    my $self = shift;
    ::is_deeply(
        $self->{feeds},
        [ 'http://usefulinc.com/edd/blog/rss91',
          'http://www.netsplit.com/blog/index.rss',
          'http://www.gnome.org/~jdub/blog/?flav=rss',
          'http://blog.clearairturbulence.org/?flav=rss',
          'http://www.hadess.net/diary.rss' ],
    );
}
