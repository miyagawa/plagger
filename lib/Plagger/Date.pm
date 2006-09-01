package Plagger::Date;
use strict;
use base qw( DateTime );

use Encode;
use DateTime::Format::Strptime;
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

    # If parsed datetime is floating, don't set timezone here. It should be "fixed" in caller plugins
    unless ($dt->time_zone->is_floating) {
        $dt->set_time_zone( Plagger->context->conf->{timezone} || 'local' );
    }

    bless $dt, $class;
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

    my $module;
    if (ref $format) {
        $module = $format;
    } else {
        $module = "DateTime::Format::$format";
        $module->require or die $@;
    }

    $module->format_datetime($self);
}

sub set_time_zone {
    my $self = shift;

    eval {
        $self->SUPER::set_time_zone(@_);
    };
    if ($@) {
        $self->SUPER::set_time_zone('UTC');
    }

    return $self;
}

sub serialize {
    my $self = shift;
    $self->format('W3CDTF');
}

1;

__END__

=head1 NAME

Plagger::Date - DateTime subclass for Plagger

=head1 SYNOPSIS



=head1 DESCRIPTION

This module subclasses DataTime for plagger's own needs.

=over

=item rebless

...

=item parse

...

=item parse_dwim

...

=item strptime

...

=item now

...

=item from_epoch

...

=item format($format)

Convience method.  Returns the datetime in the format
passed (either a formatter object or a blessed reference) 

=item set_time_zone

Overides default behavior to default to UTC if the passed
time zone isn't a legal

=item serialize

Returns the object as a W3CDTF string.

=cut

=back

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

See I<AUTHORS> file for the name of all the contributors.

=head1 LICENSE

Except where otherwise noted, Plagger is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<http://plagger.org/>, L<DateTime>

=cut