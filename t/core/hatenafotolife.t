use strict;
use Test::More tests => 3;
use FindBin;

use Plagger;

Plagger->bootstrap(config => \<<CONFIG);
global:
  log:
    level: error
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$FindBin::Bin/hatenafotolife.rdf
  - module: Test::Hatena
CONFIG

package Plagger::Plugin::Test::Hatena;

use base qw( Plagger::Plugin );

sub register {
    my($self, $context) = @_;

    $context->register_hook(
        $self,
        'aggregator.finalize' => \&test,
    );
}

sub test {
    my($self, $context, $args) = @_;

    my @feeds = $context->update->feeds;

    ::is( ($feeds[0]->entries)[0]->enclosures->[0]->url, 'http://f.hatena.ne.jp/images/fotolife/m/miyagawa/20060529/20060529191228.gif' );
    ::is( ($feeds[0]->entries)[0]->enclosures->[0]->type, 'image/gif' );
    ::is( ($feeds[0]->entries)[0]->icon->{url}, 'http://f.hatena.ne.jp/images/fotolife/m/miyagawa/20060529/20060529191228_m.jpg' );
}

