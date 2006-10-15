#!/usr/bin/perl -w
use strict;
use utf8;
use DateTime;
use DateTime::Format::W3CDTF;
use Encode;
use LWP::Simple ();
use HTML::TreeBuilder::XPath;
use URI;
use YAML;

my $url  = "http://www.wowow.co.jp/liga/contents/top.html";
my $html = decode('shift_jis', LWP::Simple::get($url));
my $tree = HTML::TreeBuilder::XPath->new;
$tree->parse($html);
$tree->eof;

my $feed = {
    title => 'WOWOW リーガ・エスパニョーラ番組表',
    link  => "http://www.wowow.co.jp/liga/",
};

my @teams = $tree->findnodes(q(//table[@width=573]/tr/td/img[@width=90]));
my @dates = $tree->findnodes(q(//table[@width=368]/tr/td[@class="date"]));
my @links = $tree->findnodes(q(//p[@class="cardview"]/a));

while (my($t1, $t2) = splice(@teams, 0, 2)) {
    my $link = (shift @links)->attr('href');
    # onair, repeat
    for (1..2) {
        my($date, $channel) = munge_datetime(shift @dates);

        push @{$feed->{entry}}, {
            title => $t1->attr('alt') . ' vs ' . $t2->attr('alt'),
            link  => URI->new_abs($link, $url)->as_string,
            date  => $date,
            tags  => [ $channel ],
        };
    }
}

binmode STDOUT, ":utf8";
print YAML::Dump $feed;

sub munge_datetime {
    my $date = shift->content->[0];

    # 10月15日（日）深夜2:55　WOWOW/BS-5ch/191ch 
    $date =~ m!^\s*(\d{1,2})月(\d{1,2})日（.*?）\s*(午前|午後|深夜)(\d{1,2}):(\d{2})\s*WOWOW.*?/(\d+ch)!
        or die "No match: $date";
    my($month, $day, $am_pm_midnight, $hour, $minute, $channel) = ($1, $2, $3, $4, $5, $6);
    $hour += 12 if $am_pm_midnight eq '午後';

    my $dt = DateTime->new(
        year  => DateTime->now->year,
        month => $month,
        day   => $day,
        hour  => $hour,
        minute => $minute,
        time_zone => 'Asia/Tokyo',
    );
    $dt->add( days => 1 ) if $am_pm_midnight eq '深夜';

    return DateTime::Format::W3CDTF->format_datetime($dt), $channel;
}

