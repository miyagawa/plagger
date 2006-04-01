package Plagger::Util;
use strict;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw( strip_html dumbnail decode_content extract_title );

use Encode ();
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

sub decode_content {
    my $res = shift;
    my $content = $res->content;

    my $charset = ($res->http_response->content_type =~ /charset=([\w\-]+)/)[0];
    unless ($charset) {
        $charset = ( $content =~ m!<meta http-equiv="Content-Type" content=".*charset=([\w\-]+)"! )[0] || "utf-8";
    }

    return Encode::decode($charset, $content);
}

sub extract_title {
    my $content = shift;
    my $title = ($content =~ m!<title>\s*(.*?)\s*</title>!s)[0] or return;
    HTML::Entities::decode($1);
}

1;
