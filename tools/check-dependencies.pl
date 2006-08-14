#!/usr/bin/perl
use strict;
use warnings;

use FindBin;
chdir "$FindBin::Bin/..";

use YAML;

my $deps = check_dependencies();
print Dump $deps;

sub check_dependencies {
    my %deps;

    # hack Module::Install to collect requires/recommends
    $INC{"inc/Module/Install.pm"} = __PACKAGE__;

    package Makefile;
    no warnings 'once';
    *tests = *name = *all_from = *features = *tests = *use_test_base =
    *auto_include = *auto_install = *install_script = *WriteAll = sub { };

    *requires = *recommends = *build_requires = sub {
        my $module = shift;
        eval qq{ require $module };
        if ($@) {
            $deps{$module} = 'missing';
        } else {
            $deps{$module} = $module->VERSION;
        }
    };

    do "Makefile.PL";

    return \%deps;
}
