package Plagger::Plugin::Notify::OpenBrowser::darwin;
use base qw( Plagger::Plugin::Notify::OpenBrowser );

use strict;

sub open {
    my ($self, $link) = @_;
    system 'open', $link;
}

1;
