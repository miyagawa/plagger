sub handle {
    my($self, $args) = @_;
    $args->{content} =~ m!<meta name="generator" content="(?:http://www\.typepad\.com/|Movable Type.*?)" />!;
}

sub extract_body {
    my($self, $args) = @_;
    my $body = ($args->{content} =~ m!<div class="entry-body-text">(.*?)</div>!s)[0];
    if ($body && ($args->{content} =~ m!<div class="entry-more-text">(.*?)</div>!s)[0]) {
        $body .= $1;
    }
    $body;
}
