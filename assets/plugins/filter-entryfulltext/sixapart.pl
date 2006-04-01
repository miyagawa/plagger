sub handle {
    my($self, $args) = @_;
    $args->{content} =~ m!<meta name="generator" content="(?:http://www\.typepad\.com/|Movable Type.*?)" />!;
}

sub extract_body {
    my($self, $content) = @_;
    my $body = ($content =~ m!<div class="entry-body-text">(.*?)</div>!s)[0];
    if ($body && ($content =~ m!<div class="entry-more-text">(.*?)</div>!s)[0]) {
        $body .= $1;
    }
    $body;
}
