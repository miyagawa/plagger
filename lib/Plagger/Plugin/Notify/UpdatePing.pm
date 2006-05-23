package Plagger::Plugin::Notify::UpdatePing;
use strict;
use base qw( Plagger::Plugin );

use XMLRPC::Lite;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'publish.feed' => \&feed,
    );
}

sub feed {
    my($self, $context, $args) = @_;

    my $feed = $args->{feed};

    my $urls = $self->conf->{url};
    $urls = [ $urls ] unless ref $urls;

    my @args = (XMLRPC::Data->type(string => $feed->title), $feed->link);

    for my $url (@$urls) {
        $context->log(info => "Ping " . $feed->link . " to $url");
        XMLRPC::Lite->new->proxy($url)->call('weblogUpdates.ping', @args);
    }
}

1;

__END__

=head1 NAME

Plagger::Plugin::Notify::UpdatePing - Notify updates via XMLRPC update ping

=head1 SYNOPSIS

  - module: Notify::UpdatePing
    config:
      url: http://www.bloglines.com/ping

=head1 DESCRIPTION

This plugin notifies feed updates to update ping servers using XML-RPC.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<XMLRPC::Lite>

=cut
