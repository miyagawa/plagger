package Plagger::Util;
use strict;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw( strip_html );

use HTML::Entities;

sub strip_html {
    my $html = shift;
    $html =~ s/<[^>]*>//g;
    HTML::Entities::decode($html);
}

1;
