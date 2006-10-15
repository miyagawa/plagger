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

my $url  = "http://www.jsports.co.jp/tv/football/card/football.html";
my $html = decode('shift_jis', LWP::Simple::get($url));
my $tree = HTML::TreeBuilder::XPath->new;
$tree->parse($html);
$tree->eof;

my $feed = {
    title => 'JSPORTS 海外サッカー放送スケジュール',
    link  => $url,
};

my @cols = $tree->findnodes(q(//table[@class='leagueTitle']/tr/td/h3|//table[@class='scheduleTable']/tr/td));

my $current_league;
while (my $node = shift @cols) {
    if ($node->tag eq 'h3') {
        $current_league = $node->as_text;
        next;
    }

    my($date, $hour, $title, $mark, $card, $channel) = ($node, splice(@cols, 0, 5));

    push @{$feed->{entry}}, {
        title => $title->as_text . " " . $card->as_text,
        date  => munge_datetime($date->as_text, $hour->as_text),
        tags  => [ $mark->content->[0]->attr('alt'), $channel->as_text ],
    };
}

binmode STDOUT, ":utf8";
print YAML::Dump $feed;

sub munge_datetime {
    my($date, $hour) = @_;

    # $date: 10月15日 $hour: 26:00
    $date =~ m!^(\d{1,2})月(\d{1,2})日! or die "No match: $date";
    my($month, $day) = ($1, $2);
    $hour =~ m!^(\d{1,2}):(\d\d)$!      or die "No match: $hour";
    ($hour, my $min)  = ($1, $2);

    my $dt = DateTime->new(
        year  => DateTime->now->year,
        month => $month,
        day   => $day,
        hour  => $hour >= 24 ? $hour - 24 : $hour,
        minute => $min,
        time_zone => 'Asia/Tokyo',
    );
    $dt->add( days => 1 ) if $hour >= 24;

    return DateTime::Format::W3CDTF->format_datetime($dt);
}
