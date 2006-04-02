use HTML::ResolveLink;

sub handle {
    my ( $self, $args ) = @_;
    $args->{entry}->link =~ qr!^http://chuspo\.chunichi\.co\.jp/dragons/tp!;
}

sub extract {
    my ( $self, $args ) = @_;

    if ( $args->{content}
        =~ m!(\d{4}.*?\d{1,2}.*?\d{1,2}).*?<FONT size="6".*?>(.*?)</FONT>.*?<FONT size="5".*?>(.*?)</FONT>.*?<FONT size=3>(.*?<BR>.*?)</FONT>!is
        )
    {
        return {
            body =>
                HTML::ResolveLink->new( base => $args->{entry}->permalink )
                ->resolve("<h2>$2 - $3</h2>\n$4"),
            date => Plagger::Date->strptime( "%Y年%m月%d日", $1 ),
        };
    }
    return;
}
