sub handle {
    my($self, $args) = @_;
    $args->{content} =~ m|<!-- google_ad_section_start|;
}

sub extract {
    my($self, $args) = @_;

    if ( $args->{content} =~ m|<!-- google_ad_section_start\S* -->(.*?)<!-- google_ad_section_end\S*? -->|s ) {
        return $1;
    }
    return;
}

