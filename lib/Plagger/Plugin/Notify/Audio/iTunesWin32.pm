package Plagger::Plugin::Notify::Audio::iTunesWin32;
use strict;
use base qw( Plagger::Plugin::Notify::Audio );

use Win32::OLE;

sub play {
    my($self, $filename) = @_;
    $filename or return $self->log(error => "filename is not set");

    my $itunes = Win32::OLE->new("iTunes.Application");
    $itunes->PlayFile($filename);
}

1;
