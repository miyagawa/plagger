#!/usr/bin/perl
use warnings;
use strict;
use File::Path;
use File::Temp qw(tempdir);
use YAML;

our $repo = "http://svn.bulknews.net/repos/plagger";
our $file = "$ENV{HOME}/.plagger-smoke.yml";

my $config  = eval { YAML::LoadFile($file) } || {};
my $current = get_current($repo);

$config->{revision} ||= $current - 1;

while ($config->{revision}++ <= $current) {
    run_chimps($config->{revision});
}

YAML::DumpFile($file, $config);

sub run_chimps {
    my $revision = shift;

    my $workdir  = tempdir(CLEANUP => 1);
    my $checkout = "plagger-r$revision";

    chdir $workdir;

    if (-e $checkout) {
        die "$workdir/$checkout exists. Remove it first";
    }

    system("svn co -r $revision $repo/trunk/plagger $checkout");
    chdir $checkout;

    system("perl Makefile.PL --skip");

    warn "Running chimps-client";
    system("tools/chimps-client.pl");
    warn "Done.";

    chdir "..";
    rmtree("$workdir/$checkout");
}
