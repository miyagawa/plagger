package Plagger::Plugin::Subscription::Odeo;
use strict;
use base qw( Plagger::Plugin::Subscription::OPML );

use URI::Escape;
use HTML::Entities;

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
    $context->log(debug => "Fetch remote OPML from $uri");

    my $response = Plagger::UserAgent->new->get($uri);
    unless ($response->is_success) {
        $context->error("Fetch $uri failed: ". $response->status_line);
    }

    my $xml = $response->content;

    # fix Odeo's bad OPML
    $xml =~ s{<outline text="(.*?)" type="link" url="(http://.*?)" count="(\d+)"/>}{
        my($title, $url, $count) = ($1, $2, $3);

        $title = uri_unescape($title);
        $title =~ s/\r\n//g;
        $title =~ tr/\+/ /;
        $title = encode_html($title);
        $url   = encode_html($url);

        qq(<outline text="$title" type="rss" xmlUrl="$url" count="$count"/>)
    }eg;

    $self->load_opml($context, \$xml);
}

sub encode_html {
    HTML::Entities::encode($_[0], q("<>&));
}

1;

__END__

=head1 NAME

Plagger::Plugin::Subscription::Odeo - Odeo Subscription via OPML

=head1 SYNOPSIS

  - module: Subscription::Odeo
    config:
      account: TatsuhikoMiyagawa

=head1 DESCRIPTION

This plugin creates Subscription by fetching Odeo
L<http://www.odeo.com/> OPML by HTTP.

=head1 NOTE

We should probably better use C<rss.xml> or C<pcast.xml> they provide and
synchronizes enclosures as well, ala Bloglines Subscription plugin.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<Plagger::Plugin::Subscription::OPML>

=cut
