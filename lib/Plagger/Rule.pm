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

sub can_run {
    my($self, $hook) = @_;
    $self->{__hooks} ||= { map { $_ => 1 } @{ $self->hooks } };

    my @phase = split /\./, $hook;
    my @try   = reverse map join(".", @phase[0..$_]), 0..$#phase;

    for my $try (@try) {
        return 1 if $self->{__hooks}->{$try} || $self->{__hooks}->{"$try.*"};
    }

    return 0;
}

sub init { }

1;
