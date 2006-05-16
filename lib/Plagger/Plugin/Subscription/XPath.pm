package Plagger::Plugin::Subscription::XPath;
use strict;
use base qw( Plagger::Plugin );

use HTML::TreeBuilder::XPath;
use Plagger::Util;
use URI;

sub register {
    my($self, $context) = @_;

    $context->register_hook(
        $self,
        'subscription.load' => $self->can('load'),
    );
}

sub load {
    my($self, $context) = @_;
    my $uri = URI->new($self->conf->{url})
        or $context->error("config 'url' is missing");

    my $xhtml = Plagger::Util::load_uri($uri, $self);
    my $tree = HTML::TreeBuilder::XPath->new;
    $tree->parse($xhtml);
    $tree->eof;

    $self->find_feed($tree);
}

sub find_feed {
    my($self, $tree) = @_;
    for my $child ($tree->findnodes($self->conf->{xpath} || '//a')) {
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

Plagger::Plugin::Subscription::XPath - Use XPath expression to extract subscriptions from web pages

=head1 SYNOPSIS

  - module: Subscription::XPath
    config:
      url: http://d.hatena.ne.jp/antipop/20050628/1119966355
      xpath: //ul[@class="xoxo" or @class="subscriptionlist"]//a

=head1 DESCRIPTION

This plugin extracts subscriptions out of XHTML content, using XPath
expression to find links.

=head1 AUTHOR

youpy

=head1 SEE ALSO

L<Plagger>, L<Plagger::Plugin::Subscription::XOXO>

=cut

