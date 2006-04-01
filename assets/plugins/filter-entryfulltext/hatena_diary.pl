sub handle {
    my($self, $args) = @_;
    #$args->{entry}->link =~ qr!^http://d\.hatena\.ne\.jp/!;
}

sub extract_body {
    my($self, $content) = @_;
    ( $content =~ /<\/h3>(.*?)<\/div>/s )[0];
}

