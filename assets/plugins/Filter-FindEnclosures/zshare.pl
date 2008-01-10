sub handle {
    my ($self, $url) = @_;
    $url =~ qr!http://www.zshare.net/(download|audio)/[0-9a-f]+!;
}

sub find {
    my($self, $args) = @_;
    
    my $uri = $args->{url};
    $uri =~ s/audio/download/;
    my $response = LWP::UserAgent->new->post(
	$uri,
	['download' => 1]);
    if($response->content =~ m/('h','t','t','p'.+?')\);link/) {
	my $enclosure_url = $1;
	$enclosure_url =~ s/[',]//g;
        my $enclosure = Plagger::Enclosure->new;
        $enclosure->url($enclosure_url);
        $enclosure->auto_set_type;
        return $enclosure;
    }

    return;
}
