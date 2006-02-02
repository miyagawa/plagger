package Plagger::Update;
use strict;

sub new {
    my $class = shift;
    bless { feeds => [] }, $class;
}

sub add {
    my($self, $feed) = @_;
    push @{ $self->{feeds} }, $feed;
}

sub feeds {
    my $self = shift;
    wantarray ? @{ $self->{feeds} } : $self->{feeds};
}

1;
