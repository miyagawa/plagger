package Plagger::Plugin::Filter::Emoticon;
use strict;
use warnings;
use base qw( Plagger::Plugin );

our $VERSION = 0.01;

use Text::Emoticon;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'update.entry.fixup' => \&filter,
    );
}

sub filter {
    my($self, $context, $args) = @_;
    my $entry = $args->{entry};
    my $emoticon = Text::Emoticon->new(
        $self->conf->{driver} || 'MSN',
        %{$self->conf->{option}}
    );
    $entry->body($emoticon->filter($entry->body));
}

1;
