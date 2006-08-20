package Plagger::Plugin::Subscription::OPML;
use strict;
use base qw( Plagger::Plugin );

use Plagger::Util;
use URI;
use XML::LibXML::SAX;

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

    my $handler = Plagger::Plugin::Subscription::OPML::SAXHandler->new(
        callback => sub { $context->subscription->add(@_) },
    );

    my $parser  = XML::LibXML::SAX->new(Handler => $handler);
       $parser->parse_string($xml);
}

package Plagger::Plugin::Subscription::OPML::SAXHandler;
use base qw( XML::SAX::Base );

sub new {
    my $class = shift;
    bless { @_ }, $class;
}

sub start_element {
    my $self = shift;
    my($ref) = @_;

    if ($ref->{LocalName} eq 'outline') {
        if (_attr($ref, 'htmlUrl', 'xmlUrl')) {
            my $feed = Plagger::Feed->new;
            $feed->url(_attr($ref, 'xmlUrl'));
            $feed->link(_attr($ref, 'htmlUrl'));
            $feed->title(_attr($ref, 'title', 'text'));
            $feed->tags([ grep { defined && $_ ne 'Subscriptions' } @{$self->{containers}} ]);
            $self->{callback}->($feed);
        } else {
            my $tag = _attr($ref, 'title', 'text');
            push @{$self->{containers}}, $tag;
        }
    }
}

sub end_element {
    my $self = shift;
    my($ref) = @_;

    if ($ref->{LocalName} eq 'outline') {
        pop @{$self->{containers}};
    }
}

sub _attr {
    my($ref, @attr) = @_;

    for my $attr (@attr) {
        return $ref->{Attributes}->{"{}$attr"}->{Value}
            if defined $ref->{Attributes}->{"{}$attr"};
    }

    return;
}

package Plagger::Plugin::Subscription::OPML;

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

L<Plagger>, L<XML::LibXML::SAX>

=cut
