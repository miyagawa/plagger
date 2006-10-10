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
    my $method;
    if ($self->conf->{extended_ping}) {
        $method = 'weblogUpdates.extendedPing';
        push @args, $feed->count ? $feed->entries->[0]->permalink : $feed->link;
        push @args, $feed->url;
        push @args, join("|", map XMLRPC::Data->type(string => $_), @{ $feed->tags })
            if @{ $feed->tags };
    } else {
        $method = 'weblogUpdates.ping';
    }

    for my $url (@$urls) {
        $context->log(info => "Ping " . $feed->link . " to $url");
        my $res = eval {
            XMLRPC::Lite->new->proxy($url)->call($method, @args)->result;
        };
        if (my $err = $@ || $res->{flerror}) {
            $context->log(error => "Error sending UpdatePing: $err");
        }
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

=head1 CONFIG

=over 4

=item extended_ping

  extended_ping: 1

Whether to use I<weblogUpdates.extendedPing> method for extra
information. Defaults to 0.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<XMLRPC::Lite>

=cut
