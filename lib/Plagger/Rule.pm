package Plagger::Rule;
use strict;
use UNIVERSAL::require;

sub new {
    my($class, $config) = @_;

    if (my $exp = $config->{expression}) {
        $config->{module} = 'Expression';
    }

    my $module = delete $config->{module};
    $module = "Plagger::Rule::$module";
    $module->require or die $@;

    my $self = bless {%$config}, $module;
    $self->init();
    $self;
}

sub init { }

sub id {
    my $self = shift;
    "xxx";
}

sub as_title {
    my $self = shift;
    "xxx";
}

1;
