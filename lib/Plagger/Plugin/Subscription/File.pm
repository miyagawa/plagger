package Plagger::Plugin::Subscription::File;

use strict;
use warnings;

use base qw(Plagger::Plugin);
use Plagger::Util;

use URI;

sub register {
    my ( $self, $context ) = @_;

    $context->register_hook( $self, 'subscription.load' => \&load );
}

sub load {
    my ( $self, $context ) = @_;

    my $uri = URI->new( $self->conf->{file} )
      or $context->error("config 'file' is missing");

    $uri->scheme('file') unless $uri->scheme;

    my $output;
    if ($uri->scheme eq 'script') {
        my $script = $uri->opaque;
        $script =~ s!^//!!;
        $script = URI::Escape::uri_unescape($script);
        $output = qx($script);
        if ($?) {
            $context->log(error => "Error happend while executing '$script': $?");
            return;
        }
    } else {
        $output = Plagger::Util::load_uri($uri);
    }

    for ( split /\n/, $output ) {
        s/\#.*//;
        next if /^\s*$/;
        my $feed = Plagger::Feed->new;
        $feed->url($_);
        $context->subscription->add($feed);
    }

    return 1;
}

1;

=head1 NAME

Plagger::Plugin::Subscription::File - Store feed URLs in a file

=head1 SYNOPSIS

  - module: Subscription::File
    config:
      file: feeds.txt

=head1 DESCRIPTION

This module subscribes to feed URLs from a file, where each line is one URL.
Lines that start with # are ignored.The URLs can also point to HTML files, in
which case feed autodiscovery will happen. The C<file> configuration key can
point to any URI supported. If a scheme is not specified, 'file' is assumed.

=head1 AUTHOR

Ilmari Vacklin <ilmari.vacklin@helsinki.fi>

=head1 SEE ALSO

L<Plagger>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
