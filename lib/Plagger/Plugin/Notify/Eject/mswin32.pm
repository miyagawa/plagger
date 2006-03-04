package Plagger::Plugin::Notify::Eject::mswin32;
use base qw( Plagger::Plugin::Notify::Eject );

use strict;
use Win32::MCI::Basic;

sub eject { Win32::MCI::Basic::mciSendString("Set CDAudio Door Open Wait"); }

1;

__END__

=head1 NAME

Plagger::Plugin::Notify::Eject::mswin32 - Notify feed updates to CD Drive for MSWin32

=head1 SYNOPSIS

  - module: Notify::Eject

=head1 DESCRIPTION


=head1 AUTHOR

Kazuhiro Osawa, Fumiaki Yoshimatsu

=head1 SEE ALSO

L<Plagger>, L<Plagger::Plugin::Notify::Eject>

=cut

