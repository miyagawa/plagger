package Plagger::Plugin::Notify::Eject::darwin;
use base qw( Plagger::Plugin::Notify::Eject );

use strict;

sub eject { system 'drutil eject' }

1;

__END__

=head1 NAME

Plagger::Plugin::Notify::Eject::darwin - Notify feed updates to CD Drive for darwin

=head1 SYNOPSIS

  - module: Notify::Eject

=head1 DESCRIPTION

=head1 AUTHOR

Kazuhiro Osawa, Masahiro Nagano

=head1 SEE ALSO

L<Plagger>, L<Plagger::Plugin::Notify::Eject>

=cut
