package Plagger::Plugin::Namespace::GeoRSS;
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

    my $georss = "http://www.georss.org/georss";
    my $gml    = "http://www.opengis.net/gml";

    my $entry = $args->{orig_entry}->{entry};

    if (ref($entry) eq 'XML::Atom::Entry') {
        if (my $point = $entry->get($georss, "point")) {
            if (my $elev = $entry->get($georss, "elev")) {
                $self->extract_point($args->{entry}, $point, $elev);
            } else {
                $self->extract_point($args->{entry}, $point);
            }
        }
        # XXX HACK: get LibXML node using XML::Atom internal API
        elsif (my @where = XML::Atom::Util::nodelist($entry->elem, $georss, "where")) {
            my($p) = $where[0]->getElementsByTagName('gml:Point');
            if ($p) {
                $self->extract_point($args->{entry}, $p->textContent);
            }
        }
    } elsif (ref($entry) eq 'HASH') {
        if ($entry->{$georss}) {
            if (my $point = $entry->{$georss}->{point}) {
                if (my $elev = $entry->{$georss}->{elev}) {
                    $self->extract_point($args->{entry}, $point, $elev);
                } else {
                    $self->extract_point($args->{entry}, $point);
                }
            }
            elsif (my $where = $entry->{$georss}->{where}) {
                if (my $pos = $where->{$gml}->{Point}->{$gml}->{pos}) {
                    $self->extract_point($args->{entry}, $pos);
                }
            }
        }
    }
}

sub extract_point {
    my($self, $entry, $point, $elev) = @_;
    $point =~ s/^\s+|\s+$//g;
    $elev =~ s/^\s+|\s+$//g;
    my($lat, $lon, $alt) = split /\s+/, $point, 3;
    if (length $lat && length $lon) {
        if (length $elev) {
            $entry->location($lat, $lon, $elev);
        } elsif (length $alt) {
            $entry->location($lat, $lon, $alt);
        } else {
            $entry->location($lat, $lon);
        }
    }
}

1;
__END__

=for stopwords GeoRSS GML

=head1 NAME

Plagger::Plugin::Namespace::GeoRSS - GeoRSS module extension

=head1 SYNOPSIS

  - module: Namespace::GeoRSS

=head1 DESCRIPTION

This plugin extracts Geo location information using GeoRSS
extension. It supports both Simple and GML notation of location point.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<http://www.georss.org/>

=cut
