#!/usr/bin/perl
use warnings;
use strict;
use File::Path;
use File::Temp qw(tempdir);
use LWP::Simple;
use YAML;

our $lockdir = "$ENV{HOME}/.plagger-smoke.lock";
mkdir $lockdir, 0777 or die "Other process is running!\n";
our $rmdir  = 1;

our $repo = "http://svn.bulknews.net/repos/plagger";
our $trac = "http://plagger.org/trac";
our $file = "$ENV{HOME}/.plagger-smoke.yml";

my $config  = eval { YAML::LoadFile($file) } || {};
my $current = get_current($repo) or die "Can't get Revision from $repo";

$config->{revision} ||= $current - 1;

my $run;
while (++$config->{revision} <= $current) {
    my $branch = get_branch($config->{revision});
    run_chimps($config->{revision}, $branch);
    $run++;
}

$config->{revision} = $current;
YAML::DumpFile($file, $config) if $run;

END { rmdir $lockdir if $rmdir && -e $lockdir };

sub run_chimps {
    my($revision, $branch) = @_;

    my $workdir  = tempdir(CLEANUP => 1);
    my $checkout = "plagger-r$revision";

    chdir $workdir;

    if (-e $checkout) {
        die "$workdir/$checkout exists. Remove it first";
    }

    warn "Testing r$revision on $branch\n";

    delete $ENV{LANG}; # svn doesn't grok LANG=ja_JP.UTF-8
    system("svn co -r $revision $repo/$branch/plagger $checkout");
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

sub get_branch {
    my $revision = shift;
    my $diff = LWP::Simple::get("$trac/changeset/$revision?format=diff");
    $diff =~ m!^Index: (branches/[^/]+|trunk)/! or return $1;
    return "trunk";
}
