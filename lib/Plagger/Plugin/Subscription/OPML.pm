package Plagger::Plugin::Subscription::OPML;
use strict;
use base qw( Plagger::Plugin );

use Plagger::UserAgent;
use URI;
use XML::OPML;

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

    my $xml;
    if (ref($uri) eq 'SCALAR') {
        $xml = $$uri;
    }
    elsif ($uri->scheme =~ /^https?$/) {
        $context->log(debug => "Fetch remote OPML from $uri");

        my $response = Plagger::UserAgent->new->fetch($uri, $self);
        if ($response->is_error) {
            $context->log(error => "GET $uri failed: " .
                          $response->http_status . " " .
                          $response->http_response->message);
        }
        $xml = $response->content;
    }
    elsif ($uri->scheme eq 'file') {
        $context->log(debug => "Open local OPML file " . $uri->path);
        open my $fh, '<', $uri->path
            or $context->error( $uri->path . ": $!" );
        $xml = join '', <$fh>;
    }
    else {
        $context->error("Unsupported URI scheme: " . $uri->scheme);
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
