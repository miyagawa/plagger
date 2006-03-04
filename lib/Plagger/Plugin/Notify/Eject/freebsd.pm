package Plagger::Plugin::Notify::Eject::freebsd;
use base qw( Plagger::Plugin::Notify::Eject );

use strict;

sub eject { system '/usr/sbin/cdcontrol eject' }

1;

__END__

=head1 NAME

Plagger::Plugin::Notify::Eject::freebsd - Notify feed updates to CD Drive for freebsd

=head1 SYNOPSIS

  - module: Notify::Eject

=head1 DESCRIPTION

=head1 AUTHOR

Kazuhiro Osawa, Masafumi Otsune

=head1 SEE ALSO

L<Plagger>, L<Plagger::Plugin::Notify::Eject>

=cut

