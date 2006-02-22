package Plagger::Plugin::Subscription::Odeo;
use strict;
use base qw( Plagger::Plugin::Subscription::OPML );

sub register {
    my($self, $context) = @_;

    $context->register_hook(
        $self,
        'subscription.load' => \&load,
    );
}

sub load {
    my($self, $context) = @_;

    my $account = $self->conf->{account}
        or $context->error("config 'account' is missing");

    my $uri = URI->new("http://www.odeo.com/profile/$account/opml.xml");
    $self->load_opml($context, $uri);
}

1;

__END__

=head1 NAME

Plagger::Plugin::Subscrption::Odeo - Odeo Subscription via OPML

=head1 SYNOPSIS

  - module: Subscription::Odeo
    config:
      account: TatsuhikoMiyagawa

=head1 DESCRIPTION

This plugin creates Subscription by fetching Odeo
L<http://www.odeo.com/> OPML by HTTP.

=head1 NOTE

As of this module writing, The way Odeo escapes HTML entities and URLs
in their OPML is kind of wrong. We should probably use C<rss.xml> or
C<pcast.xml> they provide and synchronizes enclosures as well, ala
Bloglines Subscription plugin.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<Plagger::Plugin::Subscription::OPML>

=cut
