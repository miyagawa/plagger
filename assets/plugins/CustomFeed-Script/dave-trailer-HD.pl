#!/usr/bin/perl
use strict;
use warnings;

use Web::Scraper;
use URI;
use YAML;

my $want = $ARGV[0] || "1080P";

# extract HD trailers from Dave's trailer page
my $uri  = URI->new("http://www.drfoster.f2s.com/");

my $s = scraper {
    process "td>ul>li", "trailers[]" => scraper {
        process_first "li>b", title => "TEXT";
        process_first "ul>li>a[href]", url => '@href';
        process "ul>li>ul>li>a", "movies[]" => sub {
            my $elem = shift;
            return {
                text => $elem->as_text,
                href => $elem->attr('href'),
            };
        };
    };
    result "trailers";
};

my $feed = {
    title => "Dave's Trailers Page (HD)",
    link  => $uri->as_string,
};

for my $trailer (@{ $s->scrape($uri) }) {
    my @movies = grep { ($_->{text}||'') eq "HD $want" } @{$trailer->{movies} || []};
    if (@movies) {
        push @{$feed->{entries}}, {
            title => $trailer->{title},
            link  => $trailer->{url},
            enclosure => {
                url => $movies[0]->{href},
                type => "video/quicktime",
            },
        };
    }
}

use YAML;
binmode STDOUT, ":utf8";
print Dump $feed;

