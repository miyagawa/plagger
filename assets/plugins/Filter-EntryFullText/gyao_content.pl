# author: woremacx
sub handle {
    my($self, $args) = @_;
    $args->{entry}->link =~ qr!^http://www.gyao.jp/sityou/catedetail/contents_id/cnt\d+/!;
}

sub extract {
    my($self, $args) = @_;

    (my $content = $args->{content}) =~ s/\r\n/\n/g;
    my $body;

    $content =~ s{<td align="left">(.+?)</td>}{
	$body .= "<div>".$1."</div>" if $1 ne "\r\n";
    }sge;

    return $body;
}
