package Plagger::Plugin::Subscription::OPML;
use strict;
use base qw( Plagger::Plugin );

use Plagger::Util;
use URI;
use XML::OPML;

our $HAS_LIBERAL;
BEGIN {
    eval { require XML::Liberal; $HAS_LIBERAL = 1 };
}

sub register {
    my($self, $context) = @_;

    $context->register_hook(
        $self,
        'subscription.load' => \&load,
    );
}

sub load {
    my($self, $context) = @_;
    my $uri = URI->new($self->conf->{url})
        or $context->error("config 'url' is missing");

    $self->load_opml($context, $uri);
}

sub load_opml {
    my($self, $context, $uri) = @_;

    my $xml = Plagger::Util::load_uri($uri, $self);

    if ($HAS_LIBERAL) {
        my $parser = XML::Liberal->new('LibXML');
        my $doc = $parser->parse_string($xml);
        $xml = $doc->toString;
    }

    my $opml = XML::OPML->new;
    $opml->parse($xml);
    for my $outline (@{ $opml->outline }) {
        $self->walk_down($outline, $context, 0, []);
    }
}

sub walk_down {
    my($self, $outline, $context, $depth, $containers) = @_;

    if (delete $outline->{opmlvalue}) {
        my $title = delete $outline->{title};
        push @$containers, $title if $title ne 'Subscriptions';
        for my $channel (values %$outline) {
            $self->walk_down($channel, $context, $depth + 1, $containers);
        }
        pop @$containers if $title ne 'Subscriptions';
    } else {
        my $feed = Plagger::Feed->new;
        $feed->url($outline->{xmlUrl});
        $feed->link($outline->{htmlUrl});
        $feed->title($outline->{title});
        $feed->tags($containers);
        $context->subscription->add($feed);
    }
}

1;

__END__

=head1 NAME

Plagger::Plugin::Subscription::OPML - OPML subscription

=head1 SYNOPSIS

  - module: Subscription::OPML
    config:
      url: http://example.com/mySubscriptions.opml

=head1 DESCRIPTION

This plugin creates Subscription by fetching remote OPML file by HTTP
or locally (with C<file://> URI). It supports nested folder structure
of OPML subscription.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<XML::OPML>

=cut
