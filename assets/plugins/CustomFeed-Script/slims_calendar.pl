#!/usr/bin/perl
use strict;
use warnings;
use DateTime;
use DateTime::Format::W3CDTF;
use LWP::UserAgent;
use HTML::TreeBuilder::XPath;
use YAML;

my $this = DateTime->now(time_zone => 'America/Los_Angeles');
   $this->set(day => 1, hour => 0, minute => 0, second => 0);
our $url_base = "http://www.slims-sf.com/slims-bin/showcal?date=%04d-%02d";

my $feed = {
    title => "Slim's schedule",
    link  => "http://www.slims-sf.com/slims-bin/showcal",
};
my @months = ($this->clone, do { $this->add(months => 1); $this->clone }, do { $this->add(months => 1); $this->clone });
for my $month (@months) {
    fetch_calendar($month, $feed);
}

print YAML::Dump $feed;

sub fetch_calendar {
    my($month, $feed) = @_;

    my $url = sprintf $url_base, $month->year, $month->month;
    my $ua  = LWP::UserAgent->new;
    my $content = $ua->get($url)->content;

    my $tree = HTML::TreeBuilder::XPath->new;
    $tree->parse($content);

    my @node = $tree->findnodes(q(//div[@align="center"]/table/tr[@valign="top"]/td));
    for my $node (@node) {
        my $day   = ($node->look_down(_tag => 'font'))[0] or next;
        my $start = ($node->look_down(_tag => 'font', size => 1))[0] or next;

        my($hour, $min, $ampm) = $start->as_text =~ /(\d+):(\d+) (AM|PM)/ or next;
        $hour += 12 if $ampm eq 'PM';

        my $date = $month->clone;
        $date->set(
            day  => $day->as_text,
            hour => $hour,
            minute => $min,
        );

        my $headliner = ($node->look_down(_tag => 'b'))[0] or next;
        my $info      = ($node->look_down(_tag => 'a'))[0] or next;
        push @{$feed->{entries}}, {
            date  =>  DateTime::Format::W3CDTF->format_datetime($date),
            title => $headliner->as_text,
            link  => URI->new_abs( $info->attr('href'), $url )->as_string,
        };
    }
}


