package Plagger::Update;
use strict;

sub new {
    my $class = shift;
    bless { feeds => [], by_tags => {} }, $class;
}

sub add {
    my($self, $feed) = @_;
    push @{ $self->{feeds} }, $feed;
    for my $tag ( @{$feed->tags} ) {
        push @{ $self->{by_tags}->{$tag} }, $feed;
    }
}

sub delete_feed {
    my($self, $feed) = @_;
    my @feeds = grep { $_ ne $feed } $self->feeds;
    $self->{feeds} = \@feeds;

    for my $tag ( @{$feed->tags} ) {
        my @feeds = grep { $_ ne $feed } @{ $self->{by_tags}->{$tag} };
        $self->{by_tags}->{$tag} = \@feeds;
    }
}

sub feeds {
    my $self = shift;
    wantarray ? @{ $self->{feeds} } : $self->{feeds};
}

sub count {
    my $self = shift;
    scalar @{ $self->{feeds} };
}

sub feeds_by_tag {
    my($self, $tag) = @_;
    my @feeds = @{ $self->{by_tags}->{$tag} || [] };
    wantarray ? @feeds : \@feeds;
}

sub tags {
    my $self = shift;
    keys %{ $self->{by_tags} };
}

1;
