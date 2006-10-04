#!/usr/bin/perl
use strict;
use warnings;
use XML::RSS::LibXML;

my($title, $desc) = @ARGV;

my $rss = XML::RSS::LibXML->new;
$rss->channel(title => $title, link => "http://example.com/", description => $desc);
print $rss->as_string;


