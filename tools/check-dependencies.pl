#!/usr/bin/perl
use strict;
use warnings;

use FindBin;
chdir "$FindBin::Bin/..";

check_dependencies();

sub check_dependencies {
    # hack Module::Install to collect requires/recommends
    $INC{"inc/Module/Install.pm"} = __PACKAGE__;

    package Makefile;
    no warnings 'once';
    *tests = *name = *all_from = *features = *tests = *use_test_base =
    *auto_include = *auto_install = *install_script = *WriteAll = *include_deps = sub { };

    *requires = *build_requires = ::check_module(1);
    *recommends = ::check_module(0);

    do "Makefile.PL";
}

sub check_module {
    my $required = shift;

    return sub {
        my $module = shift;
        my $ver    = shift;
        eval ($ver ? qq{ use $module $ver } : qq{ use $module });
        if ($@) {
            print "$module: missing" . ($required ? " (required)" : '');
        } else {
            print "$module: " . (defined $module->VERSION ? $module->VERSION : 'undef');
        }
        print "\n";
    };
}
