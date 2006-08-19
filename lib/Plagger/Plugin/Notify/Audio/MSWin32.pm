package Plagger::Plugin::Notify::Audio::MSWin32;
use strict;
use base qw( Plagger::Plugin::Notify::Audio);

use Win32::Sound;

sub play {
    my($self, $filename) = @_;
    $filename ||= "SystemExclamation";

    Win32::Sound::Play($filename);
}

1;
