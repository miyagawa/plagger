sub handle {
    my ($self, $url) = @_;
    $url =~ qr!http://stage6\.divx\.com/.*/(?:show_)?videos?/\d+!;
}

sub find {
    my ($self, $args) = @_;
    my $url = $args->{url};

    if ($args->{content} =~ m!<a class='vdetail-down' href="http://video.stage6.com/(\d+)/(\d+).divx"!gms){
        my $enclosure = Plagger::Enclosure->new;
        $enclosure->url("http://video.stage6.com/$1/$2.divx");
        $enclosure->type('video/divx');
        $enclosure->filename("$2.divx");
        return $enclosure;
    }

    return;
}
