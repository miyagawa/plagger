#!/usr/bin/perl
use strict;
use warnings;
use YAML;

my @hosts = @ARGV
    or die "Usage: ssl-expire.pl host1 host2 ...\n";

my $output = {
    title => "SSL expire dates",
    entry => [],
};

for my $host (@hosts) {
    my $expires = expire_date($host);
    push @{$output->{entry}}, {
        title => $host,
        date  => $expires,
    };
}

sub expire_date {
    my $host = shift;

    my $res = `echo '' | openssl s_client -connect $host:443 2>/dev/null | openssl x509 -enddate -noout`;
    if ($res =~ /notAfter=(.*)/) {
        return $1;
    }
}

print YAML::Dump $output;

