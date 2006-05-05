package Plagger::Date;
use strict;
use base qw( DateTime );

use Encode;
use DateTime::Format::Strptime;
use UNIVERSAL::require;

sub rebless {
    my($class, $dt) = @_;
    bless $dt, $class;
}

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
    $class->rebless($dt);
}

sub parse_dwim {
    my($class, $str) = @_;

    require Date::Parse;
    my $time = Date::Parse::str2time($str) or return;

    $class->from_epoch($time);
}

sub strptime {
    my($class, $pattern, $date) = @_;
    Encode::_utf8_on($pattern);
    my $format = DateTime::Format::Strptime->new(pattern => $pattern);
    $class->parse($format, $date);
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
