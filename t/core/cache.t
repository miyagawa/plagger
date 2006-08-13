use strict;
use Test::More tests => 2;
use FindBin;

use Plagger;

my $config = <<CONFIG;
global:
  log:
    level: error
  cache:
    expires: 5 seconds
plugins:
  - module: Test::Cache
CONFIG

Plagger->bootstrap(config => \$config);
sleep 6;
Plagger->bootstrap(config => \$config);

package Plagger::Plugin::Test::Cache;
use base qw( Plagger::Plugin );
use Plagger::UserAgent;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'plugin.init' => \&test,
    );
}

my $set;

sub test {
    my($self, $context, $args) = @_;
    if (! $set++) {
        $self->cache->set("foo" => "bar");
        ::is $self->cache->get("foo"), "bar";
    } else {
        ::isnt $self->cache->get("foo"), "bar";
    }
}

