package Plagger::Plugin::Filter::Reverse;
use strict;
use base qw( Plagger::Plugin );

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'update.feed.fixup' => \&feed
    );
}

sub feed {
    my($self, $context, $args) = @_;

    $context->log(debug => "reverse");
    my @entries = $args->{feed}->entries;
    @entries = reverse(@entries);
    $args->{feed}->{entries} = \@entries;
}

1;
