package Plagger::Util;
use strict;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw( strip_html dumbnail decode_content extract_title load_uri mime_type_of filename_for );

use Encode ();
use List::Util qw(min);
use HTML::Entities;
use MIME::Types;
use MIME::Type;

our $Detector;

BEGIN {
    if ( eval { require Encode::Detect::Detector; 1 } ) {
        $Detector = sub { Encode::Detect::Detector::detect($_[0]) };
    } else {
        require Encode::Guess;
        $Detector = sub {
            my @guess = qw(utf-8 euc-jp shift_jis); # xxx japanese only?
            eval { Encode::Guess::guess_encoding($_[0], @guess)->name };
        };
    }
}

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
    my $stuff = shift;

    my $content;
    my $res;
    if (ref($stuff) && ref($stuff) eq 'URI::Fetch::Response') {
        $res     = $stuff;
        $content = $res->content;
    } elsif (ref($stuff)) {
        Plagger->context->error("Don't know how to decode " . ref($stuff));
    } else {
        $content = $stuff;
    }

    my $charset;

    # 1) if it is HTTP response, get charset from HTTP Content-Type header
    if ($res) {
        $charset = ($res->content_type =~ /charset=([\w\-]+)/)[0];
    }

    # 2) if there's not, try XML encoding
    $charset ||= ( $content =~ /<\?xml version="1.0" encoding="([\w\-]+)"\?>/ )[0];

    # 3) if there's not, try META tag
    $charset ||= ( $content =~ m!<meta http-equiv="Content-Type" content=".*charset=([\w\-]+)"!i )[0];

    # 4) if there's not still, try Detector/Guess
    $charset ||= $Detector->($content);

    # 5) falls back to UTF-8
    $charset ||= 'utf-8';

    my $decoded = eval { Encode::decode($charset, $content) };

    if ($@ && $@ =~ /Unknown encoding/) {
        Plagger->context->log(warn => $@);
        $charset = $Detector->($content) || 'utf-8';
        $decoded = Encode::decode($charset, $content);
    }

    $decoded;
}

sub extract_title {
    my $content = shift;
    my $title = ($content =~ m!<title>\s*(.*?)\s*</title>!is)[0] or return;
    HTML::Entities::decode($1);
}

sub load_uri {
    my($uri, $plugin) = @_;

    require Plagger::UserAgent;

    my $data;
    if (ref($uri) eq 'SCALAR') {
        $data = $$uri;
    }
    elsif ($uri->scheme =~ /^https?$/) {
        Plagger->context->log(debug => "Fetch remote file from $uri");

        my $response = Plagger::UserAgent->new->fetch($uri, $plugin);
        if ($response->is_error) {
            Plagger->context->log(error => "GET $uri failed: " .
                                  $response->http_status . " " .
                                  $response->http_response->message);
        }
        $data = decode_content($response);
    }
    elsif ($uri->scheme eq 'file') {
        Plagger->context->log(debug => "Open local file " . $uri->file);
        open my $fh, '<', $uri->file
            or Plagger->context->error( $uri->file . ": $!" );
        $data = decode_content(join '', <$fh>);
    }
    else {
        Plagger->context->error("Unsupported URI scheme: " . $uri->scheme);
    }

    return $data;
}

our $mimetypes = MIME::Types->new;
$mimetypes->addType( MIME::Type->new(type => 'video/x-flv', extensions => [ 'flv' ]) );
$mimetypes->addType( MIME::Type->new(type => 'audio/aac', extensions => [ 'm4a', '.aac' ]) );

sub mime_type_of {
    my $ext = shift;

    if (UNIVERSAL::isa($ext, 'URI')) {
        $ext = ( $ext->path =~ /\.(\w+)/ )[0];
    }

    return unless $ext;
    return $mimetypes->mimeTypeOf($ext);
}

my %entities = (
    '&' => '&amp;',
    '<' => '&lt;',
    '>' => '&gt;',
    "'" => '&quot;',
);

my $entities_re = join '|', keys %entities;

sub encode_xml {
    my $stuff = shift;
    $stuff =~ s/($entities_re)/$entities{$1}/g;
    $stuff;
}

my %formats = (
    'u' => sub { my $s = $_[0]->url;  $s =~ s!^https?://!!; $s },
    'l' => sub { my $s = $_[0]->link; $s =~ s!^https?://!!; $s },
    't' => sub { $_[0]->title },
    'i' => sub { $_[0]->id },
);

my $format_re = qr/%(u|l|t|i)/;

sub filename_for {
    my($feed, $file) = @_;
    $file =~ s{$format_re}{
        safe_filename($formats{$1}->($feed))
    }egx;
    $file;
}

sub safe_filename {
    my($path) = @_;
    $path =~ s![^\w\s]+!_!g;
    $path =~ s!\s+!_!g;
    $path;
}

1;
