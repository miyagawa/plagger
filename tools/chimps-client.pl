#!/usr/bin/perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Config;
use File::Spec;
use Test::Chimps::Client;
use Test::TAP::Model::Visual;

chdir "$FindBin::Bin/..";
check_dependencies();

my @tests = map glob, qw(t/*.t t/*/*.t t/*/*/*.t);
my $start = time;
my $model = Test::TAP::Model::Visual->new_with_tests(@tests);

my $client = Test::Chimps::Client->new(
    server => 'http://plagger.org/chimps-server',
    model  => $model,
    report_variables => {
        archname  => $Config{archname},
        committer => $ENV{USER} || $ENV{USERNAME},
        osname    => $Config{osname},
        osvers    => $Config{osvers},
        project   => 'Plagger',
        duration  => time - $start,
        revision  => get_revision(),
    },
);

my ($status, $msg) = $client->send;
if (! $status) {
    print "Error: $msg\n";
    exit(1);
}

sub get_revision {
    return
        extract_revision('svk', 'svk info', qr/Mirrored From: .*Rev\. (\d+)/) ||
        extract_revision('svn', 'svn info', qr/Revision: (\d+)/) ||
        extract_svn_revision('.svn/entries') ||
       'unknown';
}

sub extract_revision {
    my($cmd, $command, $re) = @_;

    return unless has_command($cmd);

    my $out = qx($command) or return;
    $out =~ /$re/;
    return $1;
}

sub has_command {
    my $cmd = shift;
    grep { -e File::Spec->catfile($_, $cmd) } split /:/, $ENV{PATH};
}

sub extract_svn_revision {
    my $file = shift;
    open my($fh), $file or return;
    while (<$fh>) {
        /revision="(\d+)"/ and return $1;
    }
    return;
}

sub check_dependencies {
    warn "Checking dependencies ...\n";
    my $out = `$Config{perlpath} tools/check-dependencies.pl`;

    if (my @missing = $out =~ /^(.*missing \(required\))$/mg) {
        die "You need to install dependencies first.\n", join("\n", @missing) . "\n";
    }
    warn "Done.\n";
}
