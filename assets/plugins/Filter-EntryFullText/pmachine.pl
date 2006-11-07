# author: Masafumi Otsune
sub handle {
    my($self, $args) = @_;
    $args->{content} =~ m!<a href="http://www\.pmachine\.com/">Powered by ExpressionEngine</a>!s;
}

sub extract {
    my($self, $args) = @_;
    if ($args->{content} =~ m!<div (?:id="content"|class="(?:entryBody|blogbody)")>(.*?)<div class="posted">!s){
        my $body = $1;
        return "<div>$body</div>";
    }
    return;
}
