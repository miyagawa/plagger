package Plagger::Plugin::Publish::Debug;
use strict;
use base qw( Plagger::Plugin );

our $VERSION = '0.10';

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'publish.feed' => \&feed,
    );
}

sub feed {
    my($self, $context, $args) = @_;

    if ($self->conf->{expression}) {
        eval $self->conf->{expression};
        $context->log(error => "Expression error: $@ with '" . $self->conf->{expression} . "'") if $@;
    } else {
        $context->dumper($args->{feed});
    }
}

1;
