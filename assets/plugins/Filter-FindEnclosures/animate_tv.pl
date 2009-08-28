sub handle {
    my ($self, $url) = @_;
    $url =~ qr!http://www\.animate\.tv/play\.php\?id=.+!;
}

sub find {
    my ($self, $args) = @_;
    my $url = $args->{url};

    my $ua = LWP::UserAgent->new;
    my $res = $ua->request(HTTP::Request->new(
                                      GET => $url,
                                      new HTTP::Headers(
                                          Referer => "http://www.animate.tv/radio/"
                                          )
                                      )
        );

    return if $res->is_error;

    if ($res->filename =~ /\.asx/){
        my $enclosure = Plagger::Enclosure->new;
        $enclosure->url($res->base);
        $enclosure->auto_set_type;
        $enclosure->filename($res->filename);
        return $enclosure;
    }

    return;
}
