package Plagger::Date;
use strict;
use base qw( DateTime );

use UNIVERSAL::require;

sub parse {
    my($class, $format, $date) = @_;
    my $module = "DateTime::Format::$format";
    $module->require or die $@;
    my $dt = $module->parse_datetime($date);

    if (my $context = Plagger->context) {
        $dt->set_time_zone($context->conf->{timezone});
    }

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
