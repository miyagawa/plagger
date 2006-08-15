#!/usr/bin/perl
use warnings;
use strict;
use File::Path;
use File::Temp qw(tempdir);
use LWP::Simple;
use YAML;

our $repo = "http://svn.bulknews.net/repos/plagger";
our $file = "$ENV{HOME}/.plagger-smoke.yml";

my $config  = eval { YAML::LoadFile($file) } || {};
my $current = get_current($repo) or die "Can't get Revision from $repo";

$config->{revision} ||= $current - 1;

my $run;
while (++$config->{revision} <= $current) {
    run_chimps($config->{revision});
    $run++;
}

$config->{revision} = $current;
YAML::DumpFile($file, $config) if $run;

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

sub get_current {
    my $repo = shift;
    my $html = LWP::Simple::get($repo);
    $html =~ /Revision (\d+):/ and return $1;
    return;
}
