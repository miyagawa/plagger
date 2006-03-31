package Plagger::Plugin::Filter::Romanize;
use strict;
use warnings;
use base qw( Plagger::Plugin::Filter::Base );

our $VERSION = 0.01;

use Encode;

sub filter {
    my($self, $text) = @_;

    my $result = '';
    my $count = 0;

    my @chars = $self->romanize($text);
    return (scalar(@chars), join(' ', @chars));
}

sub romanize {
    my $self = shift;
    Plagger->context->error(ref($self) . " should override romanize");
}

1;
