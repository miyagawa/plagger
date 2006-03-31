package Plagger::Plugin::Filter::Romanize::Japanese;
use strict;
use warnings;
use base qw( Plagger::Plugin::Filter::Romanize );

use Encode;
use Text::Kakasi;

sub romanize {
    my($self, $text) = @_;
    $self->{wakati} ||= Text::Kakasi->new(qw/-w -iutf8/);
    $self->{roman}  ||= Text::Kakasi->new(qw/-Ha -Ka -Ja -Ea -ka -iutf8/);
    my @wakati = split /\s+/, $self->{wakati}->get( encode("utf-8", $text) );
    [ map $self->{roman}->get($_), @wakati ];
}

1;
