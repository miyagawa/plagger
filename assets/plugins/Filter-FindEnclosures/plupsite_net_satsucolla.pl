sub handle {
    my ($self, $url) = @_;
    $url =~ qr!pulpsite\.net/satsucolla/colla/\d+\?!;
}

sub find {
    my($self, $args) = @_;

    if ($args->{content} =~ m!<IMG SRC="(http://pulpsite\.net/satsucolla/photos/\w+\.jpg)"!i) {
        my $enclosure = Plagger::Enclosure->new;
        $enclosure->url($1);
        $enclosure->auto_set_type;
        return $enclosure;
    }

    return;
}
