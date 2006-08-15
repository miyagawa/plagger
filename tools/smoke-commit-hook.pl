#!/usr/bin/perl
use warnings;
use strict;
use File::Path;
use File::Temp qw(tempdir);

our $repo = "http://svn.bulknews.net/repos/plagger";

my $revision = shift || 'HEAD';

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
