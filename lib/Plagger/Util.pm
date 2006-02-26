package Plagger::Util;
use strict;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw( strip_html );

sub strip_html {
    my $html = shift;
    $html =~ s/<[^>]*>//g;
    $html;
}

1;
