package Plagger::Plugin::Notify::Eject::linux;
use base qw( Plagger::Plugin::Notify::Eject );

use strict;

sub eject { system 'eject' }

1;

__END__

=head1 NAME

Plagger::Plugin::Notify::Eject::linux - Notify feed updates to CD Drive for linux

=head1 SYNOPSIS

  - module: Notify::Eject

=head1 DESCRIPTION


=head1 AUTHOR

Kazuhiro Osawa

=head1 SEE ALSO

L<Plagger>, L<Plagger::Plugin::Notify::Eject>

=cut

