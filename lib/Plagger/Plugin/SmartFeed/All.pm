package Plagger::Plugin::SmartFeed::All;
use strict;
use base qw( Plagger::Plugin::SmartFeed );

sub feed_init {
    my($self, $context, $args) = @_;

    my $feed = Plagger::Feed->new;
    $feed->type('smartfeed');
    $feed->id( $self->conf->{id} || ('smartfeed:all') );
    $feed->title( $self->conf->{title} || "All Entries" );
    $feed->link( $self->conf->{link} );
    $feed->description( $self->conf->{description} ) if $self->conf->{description};

    $self->{feed} = $feed;
}

sub feed_finalize {
    my($self, $context, $args) = @_;

    # because it's "All" you have to dedupe the entries
    $self->{feed}->dedupe_entries;
    $self->{feed}->sort_entries;

    $context->update->add($self->{feed}) if $self->{feed}->count;
}

1;

