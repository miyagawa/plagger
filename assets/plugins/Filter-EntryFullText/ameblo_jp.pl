sub handle_force {
    my($self, $args) = @_;
    return $args->{entry}->link =~ m!^http://ameblo\.jp/.*?/entry-\d+\.html!
           and
           $args->{entry}->body =~ m!\x{300e}\x{8457}\x{4f5c}\x{6a29}\x{4fdd}\x{8b77}\x{306e}\x{305f}\x{3081}\x{3001}\x{8a18}\x{4e8b}\x{306e}\x{4e00}\x{90e8}\x{306e}\x{307f}\x{8868}\x{793a}\x{3055}\x{308c}\x{3066}\x{304a}\x{308a}\x{307e}\x{3059}\x{3002}\x{300f}!;
}

sub handle {
    my($self, $args) = @_;
    $args->{entry}->link =~ qr!^http://ameblo\.jp/.*?/entry-\d+\.html!;
}

sub extract {
    my($self, $args) = @_;

    (my $content = $args->{content}) =~ s/\r\n/\n/g;
    if ( $content =~ m/<div class="contents">(.*?)<\!--.*?-->/s ) {
        return $1;
    }
}
