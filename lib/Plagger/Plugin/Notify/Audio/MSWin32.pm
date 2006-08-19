package Plagger::Plugin::Notify::Audio::MSWin32;
use strict;
use base qw( Plagger::Plugin::Notify::Audio);

use Win32::Sound;

sub play {
    my($self, $filename, $length) = @_;
    $filename ||= "SystemExclamation";
    $length   ||= 3;

    Win32::Sound::Play($filename, SND_ASYNC);
    sleep $length;
}

1;
