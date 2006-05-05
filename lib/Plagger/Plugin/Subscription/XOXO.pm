package Plagger::Plugin::Subscription::XOXO;
use strict;
use base qw( Plagger::Plugin );

use HTML::TreeBuilder::XPath;
use Plagger::Util;
use URI;

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

    $self->load_xoxo($context, $uri);
}

sub load_xoxo {
    my($self, $context, $uri) = @_;

    my $xhtml = Plagger::Util::load_uri($uri, $self);
    my $tree = HTML::TreeBuilder::XPath->new;
    $tree->parse($xhtml);
    $tree->eof;

    $self->find_xoxo($tree);
}

sub find_xoxo {
    my($self, $tree) = @_;

    for my $child ($tree->findnodes('//ul[@class="xoxo" or @class="subscriptionlist"]//a')) {
        my $href  = $child->attr('href') or next;
        my $title = $child->attr('title') || $child->as_text;

        my $feed = Plagger::Feed->new;
        $feed->url($href);
        $feed->title($title);

        Plagger->context->subscription->add($feed);
    }
}

1;

__END__

=head1 NAME

Plagger::Plugin::Subscription::XOXO - Subscription list with XOXO microformats

=head1 SYNOPSIS

  - module: Subscription::XOXO
    config:
      url: http://example.com/mySubscriptions.xhtml

=head1 DESCRIPTION

This plugin creates Subscription by fetching remote XOXO file by HTTP
or locally (with C<file://> URI). The parser is implemented in really
a dumb way and only supports extracting URL (I<href>) and title from A
links inside XOXO C<ul> or C<ol> tags.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<http://microformats.org/wiki/xoxo>

=cut
