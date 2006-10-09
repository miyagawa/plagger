package Plagger::Plugin::Notify::OpenBrowser::linux;
use base qw( Plagger::Plugin::Notify::OpenBrowser );

use strict;

sub open {
    my ($self, $link) = @_;
    !system 'firefox', '-new-tab', $link
        or $self->log(error => "Can't exec firefox: $?");
}

1;
