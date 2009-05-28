package Plagger::Plugin::Namespace::Geo;
use strict;
use base qw( Plagger::Plugin );

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'aggregator.entry.fixup' => \&handle,
    );
}

sub handle {
    my($self, $context, $args) = @_;
    my $geo_ns = "http://www.w3.org/2003/01/geo/wgs84_pos#";

    my $entry = $args->{orig_entry}->{entry};

    if (ref($entry) eq 'XML::Atom::Entry') {
        my($lat, $long, $alt) = map $entry->get($geo_ns, $_), qw( lat long alt );
        if (defined $lat && defined $long) {
            if (defined $alt) {
                $args->{entry}->location($lat, $long, $alt);
            } else {
                $args->{entry}->location($lat, $long);
            }
        }
    }
    elsif (ref($entry) eq 'HASH') {
        my $geo = $entry->{$geo_ns} || {};
        $geo = $geo->{Point}->{geo} if $geo->{Point};
        if (defined($geo->{lat}) && defined($geo->{long})) {
            if (defined($geo->{alt})) {
                $args->{entry}->location($geo->{lat}, $geo->{long}, $geo->{alt});
            } else {
                $args->{entry}->location($geo->{lat}, $geo->{long});
            }
        }
    }
}

1;
__END__

=head1 NAME

Plagger::Plugin::Namespace::Geo - Extract location using Geo RDF

=head1 SYNOPSIS

  - module: Namespace::Geo

=head1 DESCRIPTION

This plugin parses the Geo tagged feed extension and store the
longitude and latitude coordinates in the entry's location object.

=head1 AUTHOR

Jean-Yves Stervinou
Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>

=cut
