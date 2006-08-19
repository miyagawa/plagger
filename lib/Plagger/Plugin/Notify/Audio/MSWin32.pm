package Plagger::Plugin::Notify::Audio::MSWin32;
use strict;
use Win32::Sound;

sub play {
    my($self, $context, $filename) = @_;
    $filename ||= "SystemExclamation";

    Win32::Sound::Play($filename, SND_ASYNC);
}

1;
