package Plagger::Plugin::Subscription::PingServer;
use strict;
use base qw( Plagger::Plugin );

use HTML::RSSAutodiscovery;
use List::Util qw(first);
use Plagger::UserAgent;
use XML::LibXML;

sub register {
    my($self, $context) = @_;

    $context->register_hook(
        $self,
        'subscription.load' => \&load,
    );
}

sub load {
    my($self, $context) = @_;

    my $servers = $self->conf->{servers};
       $servers = [ $servers ] unless ref $servers;

    for my $server (@{ $servers }) {
        my $agent    = Plagger::UserAgent->new;
        my $response = $agent->fetch($server->{url});
        if ($response->is_error) {
            $context->log(error => "GET $server->{url} failed: " .
                          $response->http_status . " " .
                          $response->http_response->message);
            return;
        }

        my $link;
        my $doc = XML::LibXML->new->parse_string($response->content);
        my $items = $self->conf->{fetch_items} || 20;
        for my $node ( $doc->findnodes('/weblogUpdates/weblog')) {
            my $url = first { $_ } $node->findvalue('@url');
            next unless $url;
            $context->log(debug => "get url: $url");

            my $feed = Plagger::Feed->new;
            $feed->url($url);
            $feed->link($url);
            $feed->title(first { $_ } $node->findvalue('@name') || $url);

            last if $context->subscription->add($feed) >= $items;
        }
    }
}

1;

__END__

=head1 NAME

Plagger::Plugin::Subscription::PingServer - Subscription from ping servers

=head1 SYNOPSIS

    - module: Subscription::PingServer
      config:
        fetch_items: 20
        servers:
          - url: http://ping.bloggers.jp/changes.xml?last=100

=head1 DESCRIPTION

This plugin allows you to pingserver your subscription in C<config.yaml>.

=head1 AUTHOR

Kazuhiro Osawa

=head1 SEE ALSO

L<Plagger>

=cut
