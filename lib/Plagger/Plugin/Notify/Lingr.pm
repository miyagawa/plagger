package Plagger::Plugin::Notify::Lingr;
use strict;
use base qw( Plagger::Plugin );

use Encode;
use POE::Component::IKC::ClientLite;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'publish.entry' => \&update,
        'plugin.init'   => \&initialize,
    );
}

sub initialize {
    my($self, $context, $args) = @_;

    my $host = $self->conf->{daemon_host} || 'localhost',
    my $port = $self->conf->{daemon_port} || 9998;

    $self->{remote} = POE::Component::IKC::ClientLite::create_ikc_client(
        port    => $port,
        ip      => $host,
        name    => 'Plagger' . $$,
        timeout => 5,
    );

    unless ($self->{remote}) {
        my $msg = q{unable to connect to plagger-lingrbot process on } 
            . "$host:$port"
            . q{, if you're not running plagger-lingrbot, you should be able }
            . q{to start it with the same Notify::Lingr config you passed to }
            . q{plagger. };
        $context->log( error => $msg );
        return;
    }
}

sub update {
    my($self, $context, $args) = @_;

    $context->log(info => "Notifying " . $args->{entry}->title . " to Lingr");

    my $body = $self->templatize('notify.tt', $args);
    Encode::_utf8_off($body) if Encode::is_utf8($body);
    for my $line (split("\n", $body)) {
        $self->{remote}->post( 'notify_lingr/update', $line );
    }
}

1;
__END__

=head1 NAME

Plagger::Plugin::Notify::Lingr - Notify feed updates to Lingr

=head1 SYNOPSIS

  - module: Notify::Lingr
    config:
      api_key:  YOUR_API_KEY
      room:     plagger
      nickname: Plaggerbot

=head1 DESCRIPTION

This plugin notifies updates to Lingr using POE::Component::Client::Lingr module.

=head1 CONFIG

=over 4

=item api_key

Your Lingr API Key. Required.

=item room

Room to enter and notify the updates. Required.

=item nickname

Nickname for your bot. Defaults to I<plaggerbot>.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<POE::Component::Client::Lingr>

=cut
