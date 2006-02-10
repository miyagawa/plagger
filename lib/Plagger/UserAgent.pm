package Plagger::UserAgent;
use strict;
use base qw( LWP::UserAgent );

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new();
    $self->agent("Plagger/$Plagger::VERSION (http://plagger.bulknews.net/)");
    $self->timeout(15); # xxx to be config
    $self;
}

1;

