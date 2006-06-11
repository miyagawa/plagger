# author: Masafumi Otsune
sub handle {
    my($self, $args) = @_;
    $args->{content} =~ m!Powered by <a href="?http://www\.pmachine\.com/!si;
}

sub extract {
    my($self, $args) = @_;
    if ($args->{content} =~ m!<h2 class="title">(?:.*?)</h2>(?:</a>)?(.*?)<\!--\n<rdf:RDF!s){
        my $body = $1;
        return "<div>$body</div>";
    }
    return;
}
