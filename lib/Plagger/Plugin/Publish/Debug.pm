package Plagger::Plugin::Publish::Debug;
use strict;
use base qw( Plagger::Plugin );

our $VERSION = '0.10';

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'publish.notify' => \&notify,
    );
}

sub notify {
    my($self, $context, $feed) = @_;
    $context->dumper($feed);
}

1;
