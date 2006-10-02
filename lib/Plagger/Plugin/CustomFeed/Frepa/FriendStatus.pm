package Plagger::Plugin::CustomFeed::Frepa::FriendStatus;
use strict;
use warnings;
use HTML::Entities;
use Encode;

sub title { 'フレ友の最新ひとこと' }

sub start_url { 'http://www.frepa.livedoor.com/friend_status' }

sub get_list {
    my ($self, $mech) = @_;

    my @msgs = ();
    my $res = $mech->get($self->start_url);
    return @msgs unless $mech->success;

    my $html = decode('euc-jp', $mech->content);
    my $reg  = decode('utf-8', $self->_list_regexp());
    while ($html =~ m|$reg|igs) {
        my $time = "$1/$2/$3 $4:$5";
        my ($subject, $link, $name) =
            (decode_entities($6), decode_entities($7), decode_entities($8));

        push(@msgs, +{
            subject   => $subject,
            name      => $name,
            link      => $link,
            user_link => $link,
            time      => $time,
        });
    }
    return @msgs;
}

sub _list_regexp {
    return <<'RE';
<tr>
<th>(\d\d\d\d)\.(\d\d)\.(\d\d) (\d\d):(\d\d)</th>
<td>(.+?)\(<a href="([^"]+)">(.+?)</a>\)</td>
</tr>
RE
}

1;
