sub handle {
    my ($self, $url) = @_;
    $url =~ m!http://stage6\.divx\.com/.*videos?/(\d+)!;
}

sub needs_content { 0 }

sub find {
    my ($self, $args) = @_;

    if ($args->{url} =~ m!http://stage6\.divx\.com/.*videos?/(\d+)!) {
        my $enclosure = Plagger::Enclosure->new;
        $enclosure->url("http://video.stage6.com/$1/");
        $enclosure->type('video/divx');
        $enclosure->filename("$1.divx");
        return $enclosure;
    }

    return;
}
