package Plagger::Mechanize;
use strict;
use base qw( WWW::Mechanize );

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);

    my $conf = Plagger->context->conf->{user_agent};
    $self->agent( $conf->{agent} || "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)" );
    $self->timeout( $conf->{timeout} || 15 );

    $self;
}

1;
