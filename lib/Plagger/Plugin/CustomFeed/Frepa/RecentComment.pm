package Plagger::Plugin::CustomFeed::Frepa::RecentComment;
use strict;
use warnings;
use HTML::Entities;
use Encode;
use URI;

sub title { 'フレパのあなたの日記へのコメント' }

sub start_url { 'http://www.frepa.livedoor.com/blog/recent_comment' }

sub get_list {
    my($self, $mech, $plugin) = @_;

    my @msgs = ();
    $mech->get($self->start_url);
    return @msgs unless $mech->success;

    my $html = decode('euc-jp', $mech->content);
    my $reg  = decode('utf-8',  $self->_list_regexp);
    while ($html =~ m|$reg|igs) {
        my $time = "$1/$2/$3 $4:$5";
        my ($link, $subject, $user_link, $name) =
            (decode_entities($6), decode_entities($7), decode_entities($8), decode_entities($9));
        my $uri = URI->new_abs($link, $self->start_url);
        $link = $uri->as_string;

        # your post doesn't link to your profile, ick
        if ($user_link =~ m!www\.frepa\.livedoor\.com/$!) {
            $user_link = "http://frepa.livedoor.com/" . $plugin->conf->{livedoor_id} . "/";
        }

        push(@msgs, +{
            user_link => $user_link,
            link      => $link,
            subject   => $subject,
            name      => $name,
            time      => $time,
        });
    }
    return @msgs;
}

sub _list_regexp {
    return <<'RE';
<tr>
<th>(\d\d\d\d)\.(\d\d)\.(\d\d) (\d\d):(\d\d)</th>
<td><a href="([^"]+?)">(.+?)</a>\(<a href="([^"]+?)">(.+?)</a>\)</td>
</tr>
RE
}

1;
__END__

no detail
