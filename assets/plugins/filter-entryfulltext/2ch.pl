# author: youpy
sub handle {
    my($self, $args) = @_;
    $args->{entry}->link =~ qr!^http://\w+\.2ch\.net/.*\d+/\d+$!;
}

sub extract {
    my($self, $args) = @_;
    if($args->{entry}->link =~ m!(\d+)$!) {
        my $id = $1;
        if ($args->{content} =~ m|<dt>($id.*)</dl>|s){
            my $body = $1;
            return "<div>$body</div>";
        }
    }
    return;
}
