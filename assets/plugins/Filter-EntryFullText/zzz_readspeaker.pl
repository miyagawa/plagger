# http://www.readspeaker.com/
sub handle {
    my($self, $args) = @_;
    $args->{content} =~ m|<!-- ISI_LISTEN_START|;
}

sub extract {
    my($self, $args) = @_;

    if ( $args->{content} =~ m|<!-- ISI_LISTEN_START\S* -->(.*?)<!-- ISI_LISTEN_STOP\S*? -->|s ) {
        return $1;
    }
    return;
}

