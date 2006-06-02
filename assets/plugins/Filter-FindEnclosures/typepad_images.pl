sub handle {
    my ($self, $url) = @_;
    $url =~ qr!/\.shared/image\.html\?/photos/uncategorized/!;
}

sub find {
    my($self, $args) = @_;

    my $url = URI->new($args->{url});
    if ($url->query) {
        my $img = URI->new;
        $img->scheme($url->scheme);
        $img->host($url->host);
        $img->path($url->query);

        my $enclosure = Plagger::Enclosure->new;
        $enclosure->url($img);
        $enclosure->auto_set_type;

        return $enclosure;
    }

    return;
}
