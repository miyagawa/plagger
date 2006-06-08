# author: Masafumi Otsune
sub handle {
    my($self, $args) = @_;
    $args->{entry}->link =~ qr!^http://www\d?\.diary\.ne\.jp/user/!;
}

sub extract {
    my($self, $args) = @_;

    my $data;
    my $fragment = ( $args->{entry}->link =~ /\#(\d+)$/ )[0];
    $data->{date} = Plagger::Date->from_epoch(epoch => $fragment);
    my $match = qq!<a name="$fragment">.*?</tr></table>(.*?)<table border=0!;
    if ( $args->{content} =~ /$match/s ){
        $data->{body} = "<div>$1</div>";
    }
    return $data;
}
