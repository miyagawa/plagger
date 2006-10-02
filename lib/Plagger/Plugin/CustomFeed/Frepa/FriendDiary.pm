package Plagger::Plugin::CustomFeed::Frepa::FriendDiary;
use strict;
use warnings;
use HTML::Entities;
use Encode;

sub title { 'フレ友の日記' }

sub start_url { 'http://www.frepa.livedoor.com/home/friend_blog/' }

sub get_list {
    my ($self, $mech) = @_;

    my @msgs = ();
    my $res = $mech->get($self->start_url);
    return @msgs unless $mech->success;

    my $html = decode('euc-jp', $mech->content);
    my $reg  = decode('utf-8', $self->_list_regexp());
    while ($html =~ m|$reg|igs) {
        my $time = "$1/$2/$3 $4:$5";
        my ($link, $subject, $user_link, $name) =
            (decode_entities($6), decode_entities($7), decode_entities($8), decode_entities($9));

        push(@msgs, +{
            link      => $link,
            subject   => $subject,
            name      => $name,
            user_link => $user_link,
            time      => $time,
        });
    }
    return @msgs;
}

sub get_detail {
    my ($self, $link, $mech) = @_;

    my $item = {};
    my $res = $mech->get($link);
    return $item unless $mech->success;

    my $html = decode('euc-jp', $mech->content);
    my $reg  = decode('utf-8', $self->_detail_regexp);
    if ($html =~ m|$reg|is) {
        $item = +{ subject => $6, description => $7};
    }

    return $item;
}

sub _list_regexp {
    return <<'RE';
<tr>
<th>(\d\d\d\d)\.(\d\d)\.(\d\d) (\d\d):(\d\d)</th>
<td><span class="frepablog">
<a href="([^"]+?/blog/show[^"]+?)">(.*?)</a>\(<a href="([^"]+?)"(?: rel="popup")?>([^"]+?)</a>\)</span>.*?
RE
}

sub _detail_regexp {
    return <<'RE';
<div class="blogcontainer">
<div class="date"><h4>(\d\d\d\d)\.(\d\d)\.(\d\d)<br />(\d\d):(\d\d)</h4></div>
<div class="blogbody">
\s*<h3>(.*?)</h3>
\s*<div class="blogbox">(.*?</p>)</div>
\s*</div>
<div class="brclear"></div>
RE
}

1;
