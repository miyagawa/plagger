package Plagger::Plugin::Notify::IRC;
use strict;
use base qw( Plagger::Plugin );

use Encode;
use POE::Component::IKC::ClientLite;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'publish.feed' => \&update,
    );
}

sub update {
    my($self, $context, $args) = @_;

    my $remote = POE::Component::IKC::ClientLite::create_ikc_client(
        port    => $self->conf->{daemon_port} || 9999,
        ip      => $self->conf->{daemon_host} || 'localhost',
        name    => "Plagger$$",
        timeout => 5,
    );

    unless ($remote) {
        $context->log(error => $POE::Component::IKC::ClientLite::error);
        return;
    }

    $context->log(info => "Notifying " . $args->{feed}->title . " to IRC");

    my $body = $self->templatize($context, $args->{feed});
    Encode::_utf8_off($body) if Encode::is_utf8($body);
    Encode::from_to($body, 'utf-8', $self->conf->{charset})
        if $self->conf->{charset} && $self->conf->{charset} ne 'utf-8';
    for my $line (split("\n", $body)) {
        $remote->post( 'notify_irc/update', $line );
    }
}

sub templatize {
    my($self, $context, $feed) = @_;
    my $tt = $context->template();
    $tt->process('irc_notify.tt', {
        feed => $feed,
    }, \my $out) or $context->error($tt->error);
    $out;
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

