sub handle {
    my ($self, $url) = @_;
    $url =~ qr!http://www.zshare.net/(download|audio)/[0-9a-f]+!;
}

sub find {
    my($self, $args) = @_;
    
    my $uri = $args->{url};
    $uri =~ s/audio/download/;
    my $response = LWP::UserAgent->new->get($uri);
    if($response->content =~ m/link = '(http:\/\/.+\.zshare\.net\/download\/[^']+?)';/) {
	my $enclosure_url = $1;
        my $enclosure = Plagger::Enclosure->new;
        $enclosure->url($enclosure_url);
        $enclosure->auto_set_type;
        return $enclosure;
    }

    return;
}
