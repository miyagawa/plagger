# add Enclosure http://www.mainichi.jp/photo/etc/
sub handle {
    my ($self, $url) = @_;
    $url =~ qr!http://www\.mainichi\.jp/[\w/]+/graph/[\d/_]+\.html$!;
}

sub find {
    my($self, $args) = @_;

    if ($args->{content} =~ m!<div class="SlidePhoto"><a href="\d+\.html"><img src="(\d+\.jpg)"!) {
        my $enclosure = Plagger::Enclosure->new;
        $enclosure->url( URI->new_abs($1, $args->{url}) );
        $enclosure->auto_set_type;
        return $enclosure;
    }

    return;
}
