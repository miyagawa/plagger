sub handle {
    my($self, $args) = @_;
    return 1 if $args->{content} =~ m!function OpenTrackback!
        and $args->{content} =~ m!<span class="posted">!;
    return;
}

sub extract {
    my($self, $args) = @_;
    my $body = ($args->{content} =~ m!<div class="blogbody">\s*<h3 class="title">.*</h3>\s*(.*?)<span class="posted">!s)[0];
    $body;
}
