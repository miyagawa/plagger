package Plagger::Plugin::Server::Protocol;
use strict;
use base qw( Plagger::Plugin::Server );
__PACKAGE__->mk_accessors( qw(status body) );

sub register {
    my($self, $context) = @_;
    $context->protocol->add_protocol($self);
}

sub proto { 'tcp' }
sub service {}

sub session_init {}
sub input {}
sub output {}

1;
