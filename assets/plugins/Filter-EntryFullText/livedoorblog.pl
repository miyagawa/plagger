sub handle_force {
    my($self, $args) = @_;
    return ($args->{entry}->link =~ qr!^http://(?:blog\.livedoor\.jp/|[\w\-]+\.livedoor\.biz/)!
             or
            $args->{content} =~ m!trackback:ping="http://app\.blog\.livedoor\.jp/!)
           and
           $args->{entry}->body =~ m!<a href=".*?">\x{7D9A}\x{304D}\x{3092}\x{8AAD}\x{3080}</a>!;
}

sub extract {
    my($self, $args) = @_;

    (my $content = $args->{content}) =~ s/\r\n/\n/g;
    if ( $content =~ m!<div class="main">(.*?)</div>\n\s*<a name="more"></a>\n\s*(?:<div class="mainmore">)?(.*?)<div class="posted">!s ) {
        return "<div>$1</div><div>$2</div>";
    }
}
