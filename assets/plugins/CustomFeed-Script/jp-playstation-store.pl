#!/usr/bin/perl
use strict;
use Web::Scraper;
use URI;
use YAML;

binmode STDOUT, ":utf8";

my $uri = URI->new("http://www.jp.playstation.com/store/");
my $scraper = scraper {
    result->{link} = $uri; # xxx
    process "title", title => 'TEXT';
    process "#Sinfo p a", 'entries[]' => { link => '@href', title => 'TEXT' };
};
my $result = $scraper->scrape($uri);

print Dump $result;




