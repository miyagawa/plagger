# author: Masafumi Otsune
sub handle {
    my($self, $args) = @_;
    $args->{content} =~ m!<div class="footer">\n.*Powered by COREBlog!
}

sub extract {
    my($self, $args) = @_;
    my $body = ($args->{content} =~ m!(<div class="category">.*?)<br clear="all" />!s)[0];
    if ($body && ($args->{content} =~ m!<a name="more"></a>\n\s*(.*?)\n?</p>!s)[0]) {
        $body .= $1;
    }
    $body;
}
