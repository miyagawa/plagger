package Plagger::Plugin::Notify::OpenBrowser::mswin32;
use base qw( Plagger::Plugin::Notify::OpenBrowser );

use strict;

sub open {
    my ($self, $link) = @_;
    system 'start', $link;
}

1;
