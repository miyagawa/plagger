# author: Masafumi Otsune
sub handle {
    my($self, $args) = @_;
    return $args->{content} =~ m!<meta name="generator" content="WordPress!
               or 
           $args->{content} =~ m!<a href="http://(?:www\.)?wordpress\.(?:xwd\.jp|org)/" title="Powered by WordPress.*?">!si;
}

sub extract {
    my($self, $args) = @_;
    if ($args->{content} =~ m#(<div class="storycontent">.*?)<div class="feedback">#s){
        return $1;
    }
    return;
}
