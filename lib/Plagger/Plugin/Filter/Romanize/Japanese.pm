package Plagger::Plugin::Filter::Romanize::Japanese;
use strict;
use warnings;
use base qw( Plagger::Plugin::Filter::Romanize );

use Encode;
use Text::Kakasi;

sub romanize {
    my($self, $text) = @_;
    $self->{kakasi} ||= Text::Kakasi->new(qw/-Ha -Ka -Ja -Ea -ka -iutf8/);
    $self->{kakasi}->get( encode("utf-8", $text) );
}

1;
