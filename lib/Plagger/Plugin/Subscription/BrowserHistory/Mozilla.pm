package Plagger::Plugin::Subscription::BrowserHistory::Mozilla;
use strict;
use base qw( Plagger::Plugin::Subscription::BrowserHistory );
use File::Mork;

use URI::file;

sub load {
    my ( $self, $context ) = @_;

    $self->conf->{ url } = URI::file->new( $self->conf->{ path } );

    my $mork = File::Mork->new( $self->conf->{ path }, verbose => 1 )
        || $context->log(error => $File::Mork::ERROR);

    foreach my $entry ( $mork->entries ) {
        my $feed = Plagger::Feed->new;
        $feed->url( $entry->URL );
        $feed->title( $entry->Name );
        $context->subscription->add( $feed );
    }
}

1;
