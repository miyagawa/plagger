package Plagger::Plugin::Subscription::Bloglines;
use strict;
use base qw( Plagger::Plugin );

our $VERSION = '0.10';
use WebService::Bloglines;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'subscription.load'    => \&load,
        'subscription.aggregate'   => \&aggregate,
    );
}

sub load {
    my($self, $context) = @_;
    $self->{bloglines} = WebService::Bloglines->new(
        username => $self->conf->{username},
        password => $self->conf->{password},
    );

    my $count = $self->{bloglines}->notify();
    $context->log(debug => "You have $count unread item(s) on Bloglines.");
    $self->{bloglines_new} = $count;
}

sub aggregate {
    my($self, $context) = @_;

    return unless $self->{bloglines_new};

    my @updates = $self->{bloglines}->getitems(0, $self->conf->{mark_unread});
    $context->log(debug => scalar(@updates) . " feed(s) updated.");

    for my $update (@updates) {
        my $feed = Plagger::Feed->new($update->feed);
        $feed->stash->{bloglines_id} = $update->feed->{bloglines}->{siteid};

        for my $item ( $update->items ) {
            $feed->add_entry( Plagger::Entry->new($item) );
        }

        $context->update->add($feed);
    }
}

1;

