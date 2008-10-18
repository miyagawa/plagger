#!/usr/bin/perl
use strict;
use warnings;
use XML::RSS::LibXML;

my $rss = XML::RSS::LibXML->new(version => '1.0');
$rss->channel(title => "Foo Bar", link => "http://example.com/");
$rss->add_item(
    title => "Entry 1",
    link  => "http://example.com/1",
    description => "Foo bar",
    content => { encoded => "OMG This is content" },
);

$rss->add_item(
    title => "Entry 2",
    link  => "http://example.com/2",
    description => "Foo bar 2",
    content => { encoded => "OMG This is content 2" },
);

print $rss->as_string;


