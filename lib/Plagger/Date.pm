package Plagger::Date;
use strict;
use base qw( DateTime );

use UNIVERSAL::require;

sub rebless { bless $_[1], $_[0] }

sub parse {
    my($class, $format, $date) = @_;

    my $module;
    if (ref $format) {
        $module = $format;
    } else {
        $module = "DateTime::Format::$format";
        $module->require or die $@;
    }

    my $dt = $module->parse_datetime($date) or return;
    if (my $context = Plagger->context) {
        $dt->set_time_zone($context->conf->{timezone} || 'local');
    }

    bless $dt, $class;
}

sub now {
    my($class, %opt) = @_;
    my $self = $class->SUPER::now();

    my $tz = $opt{timezone} || Plagger->context->conf->{timezone} || 'local';
    $self->set_time_zone($tz);

    $self;
}

sub from_epoch {
    my $class = shift;
    my %p = @_ == 1 ? (epoch => $_[0]) : @_;

    $p{time_zone} = Plagger->context->conf->{timezone} || 'local';
    $class->SUPER::from_epoch(%p);
}

sub format {
    my($self, $format) = @_;
    my $module = "DateTime::Format::$format";
    $module->require or die $@;

    $module->format_datetime($self);
}

1;
