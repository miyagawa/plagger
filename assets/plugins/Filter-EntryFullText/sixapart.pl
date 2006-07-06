sub handle {
    my($self, $args) = @_;
    return 1 if $args->{content} =~ m!<html[^>]+id="sixapart-standard"!;
    return 1 if $args->{content} =~ m!<meta name="generator" content="(?:http://www\.typepad\.com/|Movable Type.*?)" />!;
    return;
}

sub extract {
    my($self, $args) = @_;
    my $body = ($args->{content} =~ m!<div class="entry-body(?:-text)?">(.*?)</div>!s)[0];
    if ($body && ($args->{content} =~ m!<div (?:id="\w+" )?class="entry-more(?:-text)?">(.*?)</div>!s)[0]) {
        $body .= $1;
    }
    $body;
}
