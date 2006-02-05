package Plagger::Subscription;
use strict;
use base qw( Plagger::Update );

sub new {
    my $class = shift;
    bless { feeds => [], by_tags => {}, by_types => {} }, $class;
}

sub add {
    my($self, $feed) = @_;
    push @{ $self->{feeds} }, $feed;
    for my $tag ( @{$feed->tags} ) {
        push @{ $self->{by_tags}->{$tag} }, $feed;
    }
    push @{ $self->{by_types}->{$feed->type} }, $feed;
}

sub types {
    my $self = shift;
    keys %{ $self->{by_types} };
}

sub feeds_by_type {
    my($self, $type) = @_;
    @{ $self->{by_types}->{$type} || [] };
}

1;
