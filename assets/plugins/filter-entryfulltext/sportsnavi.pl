sub handle {
    my($self, $args) = @_;
    $args->{entry}->link =~ qr!^http://sportsnavi\.yahoo\.co\.jp/.*/headlines/!
}

sub extract {
    my($self, $args) = @_;
    if ( $args->{content} =~ /<span class="user1"><span class="line15">(.*?)<!-- \d+.*? -->.*?\[ .*? (\d+.*?) \]/s ) {
        return {
            body => $1,
            date => Plagger::Date->strptime("%Y年%m月%d日 %H:%M", $2),
        }
    }
    return;
}
