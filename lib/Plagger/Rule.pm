package Plagger::Rule;
use strict;
use UNIVERSAL::require;

sub new {
    my($class, $config) = @_;

    my $module = delete $config->{module};
    $module = "Plagger::Rule::$module";
    $module->require or die $@;

    my $self = bless {%$config}, $module;
    $self->init();
    $self;
}

sub init { }

1;
