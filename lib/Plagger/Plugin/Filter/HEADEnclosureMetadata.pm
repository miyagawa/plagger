package Plagger::Plugin::Filter::HEADEnclosureMetadata;
use strict;
use base qw( Plagger::Plugin );

use File::Basename;
use Plagger::UserAgent;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'update.entry.fixup' => \&filter,
    );
}

sub filter {
    my($self, $context, $args) = @_;

    for my $enclosure ($args->{entry}->enclosures) {
        next if $enclosure->length or !$enclosure->url;

        my $meta = $self->cache->get_callback(
            $enclosure->url,
            sub { $self->fetch_metadata($enclosure->url) },
            '1 day',
        );

        unless ($meta) {
            $context->log(error => "Can't get metadata from " . $enclosure->url);
            next;
        }

        if ($meta->{length}) {
            $enclosure->length($meta->{length}) ;
            $context->log(info => "Set length of " . $enclosure->url . ": $meta->{length}");
        }

        if ($meta->{type} &&
            (!$enclosure->type ||
             $meta->{type} !~ m!^(?:text/|application/octet-stream)! &&
             $enclosure->type ne $meta->{type})) {
            $enclosure->type($meta->{type});
            $context->log(info => "Set type of " . $enclosure->url . ": $meta->{type}");
        }

        if ($meta->{filename}) {
            $enclosure->filename($meta->{filename});
            $context->log(info => "Set filename of " . $enclosure->url . ": $meta->{filename}");
        }
    }
}

sub fetch_metadata {
    my($self, $url) = @_;

    Plagger->context->log(debug => "sending HEAD to $url");

    my $ua  = Plagger::UserAgent->new;
    my $req = HTTP::Request->new(HEAD => $url);

    my $res = $ua->request($req);
    return if $res->is_error;

    return {
        'length' => _header($res, 'Content-Length'),
        'type'   => _header($res, 'Content-Type'),
        'filename' => scalar _filename($res),
    };
}

sub _header {
    my($res, $header) = @_;

    my $value = $res->header($header) or return undef; ## no critic
    $value =~ s/;.*?$//;
    $value;
}

sub _filename {
    my $res = shift;
    my $value = $res->header('Content-Disposition') or return;

    my $filename = ( $value =~ /; filename=(\S*)/ )[0] or return;
    $filename =~ s/^"(.*?)"$/$1/;
    $filename;
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::HEADEnclosureMetadata - Fetch enclosure metadata by sending HEAD request(s)

=head1 SYNOPSIS

  - module: Filter::FetchEnclosure
    config:
      dir: /path/to/files

=head1 DESCRIPTION

This plugin downloads enclosure files set for each entry.

=head1 TODO

=over 4

=item Support asynchronous download using POE

=back

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>

=cut

