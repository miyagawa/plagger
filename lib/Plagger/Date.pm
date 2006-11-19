package Plagger::Date;
use strict;
use base qw( DateTime );

use Encode;
use DateTime::Format::Strptime;
use DateTime::TimeZone;
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
    bless $dt, $class;
}

sub parse_dwim {
    my($class, $str) = @_;

    # check if it's Japanese
    if ($str =~ /^(\x{5E73}\x{6210}|\x{662D}\x{548C}|\x{5927}\x{6B63}|\x{660E}\x{6CBB})/) {
        eval { require DateTime::Format::Japanese };
        if ($@) {
            Plagger->context->log(warn => "requires DateTime::Format::Japanese to parse '$str'");
            return;
        }
        return $class->parse( 'Japanese', encode_utf8($str) );
    }

    require Date::Parse;
    my %p;
    @p{qw( second minute hour day month year zone )} = Date::Parse::strptime($str);

    unless (defined($p{year}) && defined($p{month}) && defined($p{day})) {
        return;
    }

    $p{year} += 1900;
    $p{month}++;

    my $zone = delete $p{zone};
    for (qw( second minute hour )) {
        delete $p{$_} unless defined $p{$_};
    }

    my $dt = $class->new(%p);

    if (defined $zone) {
        my $tz = DateTime::TimeZone::offset_as_string($zone);
        $dt->set_time_zone($tz);
    }

    $dt;
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

This module subclasses DateTime for plagger's own needs.

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

Convenience method.  Returns the datetime in the format
passed (either a formatter object or a blessed reference) 

=item set_time_zone

Overrides default behavior to default to UTC if the passed
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
