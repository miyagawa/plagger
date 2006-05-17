#!/usr/bin/perl
use warnings;
use strict;
use File::Path;
use LWP::Simple;

my $version = shift @ARGV or die "Usage: release.pl version";

my $workdir  = "$ENV{HOME}/tmp";
my $checkout = "plagger-$version";

chdir $workdir;

if (-e $checkout) {
    die "$workdir/$checkout exists. Remove it first";
}

system("svk co //mirror/plagger/trunk/plagger $checkout");
chdir $checkout;

rewrite_version("lib/Plagger.pm", $version);

system("yes n | perl Makefile.PL");
system("make manifest");
system("make test");

my $url = "http://plagger.org/trac/wiki/PlaggerChangeLog?format=txt";
my $res = LWP::Simple::mirror($url, "Changes");
if ($res !~ /^[23]/) {
    die "GET $url failed: $res";
}

check_version("Changes", $version);

system("svk ci -m 'packaging $version'");
system("svk cp -m 'tag release $version' //mirror/plagger/trunk //mirror/plagger/tags/release-$version");

system("make dist");
system("cpan-upload Plagger-$version.tar.gz");

chdir "..";
system("svk co --detach $checkout");
rmtree("$workdir/$checkout");

sub rewrite_version {
    my($file, $version) = @_;

    open my $fh, $file or die "$file: $!";
    my $content = join '', <$fh>;
    close $fh;

    $content =~ s/^our \$VERSION = .*?;$/our \$VERSION = '$version';/m;

    open my $out, ">", "lib/Plagger.pm";
    print $out $content;
    close $out;
}

sub check_version {
    my($file, $version) = @_;

    open my $fh, $file or die "$file: $!";
    while (<$fh>) {
        /== \Q$version\E / and return 1;
    }

    die "$file doesn't contain log for $version";
}
