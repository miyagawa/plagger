#!/usr/bin/perl
use strict;
use warnings;
use Net::Domain::ExpireDate;
use YAML;

my @domains = @ARGV
    or die "Usage: domain-expire.pl domain1 domain2 ...\n";

my $output = {
    title => "Expire dates for my domains",
    entry => [],
};

for my $domain (@domains) {
    my $expires = expire_date($domain);
    push @{$output->{entry}}, {
        title => $domain,
        date  => "$expires", # stringify
    };
}

print YAML::Dump $output;

