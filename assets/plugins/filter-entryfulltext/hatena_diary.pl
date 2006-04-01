sub handle {
    my($self, $args) = @_;
    $args->{entry}->link =~ qr!^http://d\.hatena\.ne\.jp/!;
}

sub extract_body {
    my($self, $args) = @_;
    my $name     = ( $args->{entry}->link =~ /\#([\w\-]+)$/ )[0];
    my $day_only = $args->{entry}->link =~ qr!^http://d\.hatena\.ne\.jp/[\w\-]+/\d+/?$!;

    my $match =
         $name     ? qq!<h3><a href=".*?" name="$name">.*?</h3>(.*?)</div>! :
         $day_only ? qq!<div class="section">(.*?)</div>! :
                     qq!</h3>(.*?)</div>!;

    if ( $args->{content} =~ /$match/s ){
        return "<div>$1</div>";
    }
    return;
}

