package Plagger::Plugin::Notify::NetSend;
use strict;
use warnings;
use base qw(Plagger::Plugin);

use Encode;
use Net::NetSend;

sub register {
    my ($self, $context) = @_;
    $context->register_hook(
        $self,
        'publish.feed' => \&update,
    );
}

sub update {
    my ($self, $context, $args) = @_;
    my $target_netbios_name = $self->conf->{target_netbios_name};
    $target_netbios_name ||= Net::NetSend::getNbName($self->conf->{target_ip});
    unless ($target_netbios_name) {
        $context->log(error => "No netbios name found: $@");
        return;
    }
    my $body = $self->templatize($context, $args->{feed});
    my $success = Net::NetSend::sendMsg(
        $target_netbios_name,
        $self->conf->{source_netbios_name},
        $self->conf->{target_ip},
        encode('shift-jis', $body),
    );
    $context->log(error => "Error in delivery! \n$@") unless $success;
}

sub templatize {
    my ($self, $context, $feed) = @_;
    my $tt = $context->template();
    $tt->process('net_send_notify.tt', {
        feed => $feed,
    }, \my $out) or $context->error($tt->error);
    $out;
}

1;
__END__

=head1 NAME

Plagger::Plugin::Notify::NetSend - Notify feed updates to Windows Messenger Service

=head1 SYNOPSIS

  - module: Notify::NetSend
    config:
      target_netbios_name: client
      source_netbios_name: plagger
      target_ip: 192.168.0.1

=head1 DESCRIPTION

This plugin notifies feed updates to Windows Messenger Service

=head1 AUTHOR

Jiro Nishiguchi

=head1 SEE ALSO

L<Plagger>, L<Net::NetSend>

=cut
