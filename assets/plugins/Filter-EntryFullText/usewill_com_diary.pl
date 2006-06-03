# author: Tatsuya Noda
use URI;

sub handle {
    my($self, $args) = @_;
    $args->{entry}->link =~ m|http://usewill\.com/diary/\d+\.html|;
}

sub extract {
    my($self, $args) = @_;
    my $hash = URI->new($args->{entry}->permalink)->fragment;
    ($args->{content} =~
	 m!<a name="$hash">(<table .*?</a></p></td></tr></table>)<hr>!s)[0];
}
