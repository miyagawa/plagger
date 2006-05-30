package Plagger::Plugin::Subscription::FOAF;

use strict;
use warnings;

use base qw(Plagger::Plugin);
use Plagger::Util;

use XML::FOAF;

sub register {
    my ( $self, $context ) = @_;

    $context->register_hook( $self, 'subscription.load' => \&load );
}

sub load {
    my ( $self, $context ) = @_;

    my $uri = URI->new( $self->conf->{url} )
      or $context->error("config 'url' is missing");

    $self->load_foaf( $context, $uri );
}

sub load_foaf {
    my ( $self, $context, $uri ) = @_;

    my $content = Plagger::Util::load_uri($uri);

    my $person = eval { XML::FOAF->new( \$content, $uri )->person };

    unless ($person) {
        $context->log( erorr => "Error loading FOAF file $uri: " . XML::FOAF->errstr );
        return;
    }

    for my $friend ( @{ $person->knows } ) {
        my $blog = $friend->weblog or next;

        my $feed = Plagger::Feed->new;
        $feed->url($blog);

        $context->subscription->add($feed);
    }

    return 1;
}

1;

=head1 NAME

Plagger::Plugin::Subscription::FOAF - Simple subscription of friends' blogs

=head1 SYNOPSIS

  - module: Subscription::FOAF
    config:
      url: http://user.livejournal.com/data/foaf

=head1 DESCRIPTION

This module subscribes to your friends' blogs in a FOAF file.

=head1 AUTHOR

Ilmari Vacklin <ilmari.vacklin@helsinki.fi>

=head1 SEE ALSO

L<Plagger>, L<http://xmlns.com/foaf/0.1/>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
