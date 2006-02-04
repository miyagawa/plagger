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

sub feeds {
    my $self = shift;
    wantarray ? @{ $self->{feeds} } : $self->{feeds};
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
