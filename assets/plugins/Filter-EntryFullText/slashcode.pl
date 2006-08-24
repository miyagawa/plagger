sub handle {
    my($self, $args) = @_;
    $args->{entry}->permalink =~ m!article\.pl\?sid=\d\d/\d\d/\d\d/\d+|/~\w+/journal/\d+$!;
}

sub extract {
    my($self, $args) = @_;

    my $body = ($args->{content} =~ m!<div class="intro(?:text)?">(.*?)</div>!s)[0];
    if ($body && ($args->{content} =~ m!<div class="(?:bodytext|full)?">(.*?)</div>!s)[0]) {
        $body .= $1;
    }
    $body;
}
