package Plagger::Util;
use strict;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw( strip_html dumbnail );

use List::Util qw(min);
use HTML::Entities;

sub strip_html {
    my $html = shift;
    $html =~ s/<[^>]*>//g;
    HTML::Entities::decode($html);
}

sub dumbnail {
    my($img, $p) = @_;

    if (!$img->{width} && !$img->{height}) {
        return '';
    }

    if ($img->{width} <= $p->{width} && $img->{height} <= $p->{height}) {
        return qq(width="$img->{width}" height="$img->{height}");
    }

    my $ratio_w = $p->{width}  / $img->{width};
    my $ratio_h = $p->{height} / $img->{height};
    my $ratio   = min($ratio_w, $ratio_h);

    sprintf qq(width="%d" height="%d"), ($img->{width} * $ratio), ($img->{height} * $ratio);
}

1;
