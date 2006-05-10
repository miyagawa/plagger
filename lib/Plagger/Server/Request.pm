package Plagger::Server::Request;
use strict;
use base qw( Class::Accessor::Fast );
__PACKAGE__->mk_accessors( qw(protocol server) );

sub new {
    my $class = shift;
    bless {@_}, $class;
}

1;
