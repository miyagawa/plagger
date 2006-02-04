package Plagger::UserAgent;
use strict;
use base qw( LWP::UserAgent );

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new();
    $self->agent("Plagger/$Plagger::VERSION");
    $self;
}

1;

