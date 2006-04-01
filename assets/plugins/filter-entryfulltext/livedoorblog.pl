sub handle_force {
    my($self, $args) = @_;
    $args->{entry}->link =~ qr!^http://(?:blog\.livedoor\.jp/|[\w\-]+\.livedoor\.biz/)!;
}

sub extract_body {
    my($self, $content) = @_;

    $content =~ s/\r\n/\n/g;
    if ( $content =~ m!<div class="main">(.*?)</div>\n\s*<a name="more"></a>\n\s*<div class="main">(.*?)<br clear="all">\n?</div>!s ) {
        return "<div>$1</div><div>$2</div>";
    }
}
