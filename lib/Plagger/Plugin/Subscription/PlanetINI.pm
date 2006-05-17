package Plagger::Plugin::Subscription::PlanetINI;
use strict;
use base qw( Plagger::Plugin );

use Config::INI::Simple;
use Plagger::Util;
use URI;

sub register {
    my($self, $context) = @_;

    $context->register_hook(
        $self,
        'subscription.load' => \&load,
    );
}

sub load {
    my($self, $context) = @_;

    my $config = Config::INI::Simple->new;
    $config->read($self->conf->{path});

    for my $url (keys %$config) {
        next if $url !~ m!https?://!;

        my $feed = Plagger::Feed->new;
        $feed->url($url);
        $feed->title($config->{$url}->{name});

        $context->subscription->add($feed);
    }
}

1;

__END__

=head1 NAME

Plagger::Plugin::Subscription::PlanetINI - read subscriptions from Planet Planet's config.ini

=head1 SYNOPSIS

  - module: Subscription::PlanetINI
    config:
      path: /path/to/config.ini

=head1 DESCRIPTION

This plugin extracts subscriptions out of Python Planet's I<config.ini> file.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<http://planetplanet.org/>

=cut

