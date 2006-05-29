# author: mizzy

sub handle {
    my ($self, $url) = @_;
    $url =~ qr!http://(?:www.)?youtube.com/(?:watch(?:\.php)?)?\?v=.+!;
}

sub find {
    my ($self, $content) = @_;

    if ($content =~ /video_id=([^&]+)&l=\d+&t=([^&]+)/gms){
        my $enclosure = Plagger::Enclosure->new;
        $enclosure->url("http://youtube.com/get_video?video_id=$1&t=$2");
        $enclosure->type('video/flv');
        $enclosure->filename("$1.flv");
        return $enclosure;
    }

    return;
}
