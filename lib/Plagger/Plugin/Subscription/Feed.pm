package Plagger::Plugin::Subscription::Feed;
use strict;
use warnings;

use base qw( Plagger::Plugin );
use Plagger::Util;
use Plagger::FeedParser;

sub register {
    my ( $self, $context ) = @_;
    $context->register_hook(
        $self,
        'subscription.load' => \&load,
    );
}

sub load {
    my ( $self, $context ) = @_;

    # TODO: Auto-Discovery, XML::Liberal
    my $uri = URI->new( $self->conf->{url} )
      or $context->error("config 'url' is missing");

    $self->load_feed( $context, $uri );
}

sub load_feed {
    my ( $self, $context, $uri ) = @_;

    my $content = Plagger::Util::load_uri($uri);
    my $feed = eval { Plagger::FeedParser->parse(\$content) };

    unless ($feed) {
        $context->log( error => "Error loading feed $uri: $@" );
        return;
    }

    for my $entry ($feed->entries) {
        my $url = $entry->link or next;

        my $feed = Plagger::Feed->new;
        $feed->url($url);

        $context->subscription->add($feed);
    }

    return 1;
}

1;

=head1 NAME

Plagger::Plugin::Subscription::Feed - Subscribe entries in a XML feed (RSS/Atom)

=head1 SYNOPSIS

  - module: Subscription::Feed
    config:
      url: http://del.icio.us/rss/miyagawa/mycomments

=head1 DESCRIPTION

This module subscribes to entries in a XML feed.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<XML::Feed>
