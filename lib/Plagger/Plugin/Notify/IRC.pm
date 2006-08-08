package Plagger::Plugin::Notify::IRC;
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
    my $port = $self->conf->{daemon_port} || 9999;

    $self->{remote} = POE::Component::IKC::ClientLite::create_ikc_client(
        port    => $port,
        ip      => $host,
        name    => "Plagger$$",
        timeout => 5,
    );

    unless ($self->{remote}) {
        my $msg = q{unable to connect to plagger-ircbot process on } 
            . "$host:$port"
            . q{, if you're not running plagger-ircbot, you should be able }
            . q{to start it with the same Notify::IRC config you passed to }
            . q{plagger. };
        $context->log( error => $msg );
        return;
    }
}

sub update {
    my($self, $context, $args) = @_;

    $context->log(info => "Notifying " . $args->{entry}->title . " to IRC");

    my $body = $self->templatize('irc_notify.tt', $args);
    Encode::_utf8_off($body) if Encode::is_utf8($body);
    Encode::from_to($body, 'utf-8', $self->conf->{charset})
        if $self->conf->{charset} && $self->conf->{charset} ne 'utf-8';
    for my $line (split("\n", $body)) {
        $self->{remote}->post( 'notify_irc/update', $line );
    }
}

1;

__END__

=head1 NAME

Plagger::Plugin::Notify::IRC - Notify feed updates to IRC

=head1 SYNOPSIS

  - module: Notify::IRC
    config:
      daemon_port: 9999
      nickname: plaggerbot
      server_host: chat.freenode.net
      server_port: 6667
      server_channels:
        - #plagger-test
      charset: iso-2022-jp
      announce: notice

=head1 DESCRIPTION

This plugin allows you to notify feed updates to IRC channels using
POE based IRC client. This module uses IKC inter-kernal protocol to
communicate with POE daemon.

=head1 SETUP

In order to make Notify::IRC run, you need to run I<plagger-ircbot>
script first, before running the plagger main process.

  % ./bin/plagger-ircbot -c irc.yaml &

I<plagger-ircbot> is a POE process that persistently connects to an
IRC server, and this plugin uses POE IKC to talk to the bot process.

=head1 AUTHOR

Masayoshi Sekimura, Tatsuhiko Miyagawa

This module and C<plagger-ircbot.pl> code is based on Ian Langworth's
Kwiki::Notify::IRC module.

=head1 SEE ALSO

L<Plagger>, L<Kwiki::Notify::IRC>, L<POE::Component::IRC>

=cut

