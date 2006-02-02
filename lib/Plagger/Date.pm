package Plagger::Date;
use strict;
use base qw( DateTime );

use UNIVERSAL::require;

sub rebless {
    my($class, $dt) = @_;
    bless $dt, $class;
}

sub now {
    my($class, %opt) = @_;
    my $self = $class->SUPER::now();

    my $tz = $opt{timezone} || 'local';
    $self->set_time_zone($tz);

    $self;
}

sub format {
    my($self, $format) = @_;
    my $module = "DateTime::Format::$format";
    $module->require or die $@;

    $module->format_datetime($self);
}

1;
