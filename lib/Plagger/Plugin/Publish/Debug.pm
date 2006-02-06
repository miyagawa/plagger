package Plagger::Plugin::Publish::Debug;
use strict;
use base qw( Plagger::Plugin );

our $VERSION = '0.10';

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'publish.add_feed' => \&add_feed,
    );
}

sub add_feed {
    my($self, $context, $args) = @_;
    $context->dumper($args->{feed});
}

1;
