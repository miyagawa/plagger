package Plagger::Plugin::CustomFeed::Config;
use strict;
use warnings;
use base qw (Plagger::Plugin);

our $VERSION = 0.01;

sub register {
    my ($self, $context) = @_;
    $context->register_hook(
        $self,
        'subscription.load' => \&load,
        'aggregator.aggregate.config' => \&aggregate,
    );
}

sub load {
    my ($self, $context) = @_;
    my $feed = Plagger::Feed->new;
    $feed->type('config');
    $context->subscription->add($feed);
}

sub aggregate {
    my ($self, $context, $args) = @_;

    my $feed = Plagger::Feed->new;
    $feed->type('config');
    for (keys %{$self->conf}) {
        next if $_ eq 'entry';
        $feed->$_($self->conf->{$_});
    }

    for my $entry_conf (@{$self->conf->{entry}}) {
        my $entry = Plagger::Entry->new;
        $entry->$_($entry_conf->{$_}) for keys %$entry_conf;
        $feed->add_entry($entry);
    }

    $context->update->add($feed);
}

1;

