sub handle {
    my ($self, $url) = @_;
    $url =~ qr!http://www\.yourfilehost\.com/media\.php\?!;
}

sub find {
    my ($self, $args) = @_;

    if ($args->{content} =~ m!<a href="([^\"]*)">DOWNLOAD\s*THIS FILE</a>!s) { 
        my $enclosure = Plagger::Enclosure->new;
        $enclosure->url($1);
        $enclosure->auto_set_type;
        return $enclosure;
    }

    return;
}
