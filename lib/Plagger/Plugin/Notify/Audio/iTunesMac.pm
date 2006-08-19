package Plagger::Plugin::Notify::Audio::iTunesMac;
use strict;
use base qw( Plagger::Plugin::Notify::Audio);

use Mac::iTunes;

sub play {
    my($self, $filename, $length) = @_;

    my $playlist = ref $self;
    my $itunes = Mac::iTunes->controller;

    $itunes->delete_playlist($playlist);
    $itunes->add_track($filename, $playlist);
    $itunes->play_track(1, $playlist);
    sleep $length;
}

1;
