use URI::Escape;

sub handle {
    my ($self, $url) = @_;
    $url =~ qr!http://www\.dailymotion\.com.*?/video/\w+?_[^/]+$!;
}

sub find {
    my ($self, $args) = @_;
    my $url = $args->{url};

    if ($args->{content} =~ m!"url=(.*?)\.flv&duration=!gms){
        my $enclosure_uri = uri_unescape($1);
        my($filename) = $enclosure_uri =~ m!/flv/(\d+\.flv)\?!;
        my $enclosure = Plagger::Enclosure->new;
        $enclosure->url($enclosure_uri);
        $enclosure->type('video/flv');
        $enclosure->filename($filename);
        return $enclosure;
    }

    return;
}
