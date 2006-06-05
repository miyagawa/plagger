sub handle {
    my ($self, $url) = @_;
    $url =~ qr!watch\.impress\.co\.jp/cda/parts/image_for_link/!;
}

sub find {
    my($self, $args) = @_;

    if ($args->{content} =~ m!<IMG SRC="(/cda/static/image/.*?)"!i) {
        my $enclosure = Plagger::Enclosure->new;
        $enclosure->url( URI->new_abs($1, $args->{url}) );
        $enclosure->auto_set_type;
        return $enclosure;
    }

    return;
}
