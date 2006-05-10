package Plagger::Server::Protocol;
use strict;

sub new {
    my $class = shift;
    bless {
        protocols  => [],
    }, $class;
}

sub add_protocol {
    my($self, $protocol) = @_;
    push @{ $self->{protocols} }, $protocol;
}

sub delete_protocol {
    my($self, $protocol) = @_;
    my @protocols = grep { $_ ne $protocol } $self->protocols;
    $self->{protocols} = \@protocols;
}

sub protocols {
    my $self = shift;
    wantarray ? @{ $self->{protocols} } : $self->{protocols};
}

sub count {
    my $self = shift;
    scalar @{ $self->{protocols} };
}

1;

