package Plagger::Plugin::Subscription::BrowserHistory::Safari;
use strict;
use base qw( Plagger::Plugin::Subscription::BrowserHistory );
use Mac::Tie::PList;

use URI::file;
		
sub load {
    my ( $self, $context ) = @_;

    $self->conf->{ url } = URI::file->new( $self->conf->{ path } );

    my $plist = Mac::Tie::PList->new_from_file( $self->conf->{ path } );

	foreach my $entry (@{$plist->{WebHistoryDates}}){
		my $feed = Plagger::Feed->new;
        $feed->url( $entry->{''} );
        $feed->title( $entry->{title} );
        $context->subscription->add( $feed );
	}
}

1;
