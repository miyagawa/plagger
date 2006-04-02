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
            body => "<h2>$2 - $3</h2>\n$4",
            date => Plagger::Date->strptime( "%Y年%m月%d日", $1 ),
        };
    }
    return;
}

=head1 NAME

chuspo_dragons

=head1 SYNOPSIS

  - module: Subscription::Config
    config:
      feed:
        - url: http://chuspo.chunichi.co.jp/dragons/tp2006/tlist.htm
          meta:
            follow_link: "^tp"

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

==head1 LICENSE

Except where otherwise noted, Plagger is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<http://plagger.org/>

=cut

