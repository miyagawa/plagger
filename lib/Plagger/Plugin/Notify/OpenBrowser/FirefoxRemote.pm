package Plagger::Plugin::Notify::OpenBrowser::FirefoxRemote;
use base qw( Plagger::Plugin::Notify::OpenBrowser );

use strict;
use Net::Telnet;

sub init {
    my $self = shift;
    $self->Plagger::Plugin::init(@_); # Don't call SUPER::init which does auto-dispatch
}

sub open {
    my($self, $link) = @_;

    $self->{conn} ||= do {
        my $host = $self->conf->{host} || "localhost";
        my $port = $self->conf->{port} || 4242;
        my $telnet = Net::Telnet->new(Port => $port);
        $telnet->open($host)
            or return $self->log(error => "Can't connect to $host:$port");
        $self->log(info => "Connect MozRepl at $host:$port");
        $telnet;
    };

    $self->log(info => "Open $link in a remote Firefox");
    $self->{conn}->cmd("window.openNewTabWith('$link')");
}

1;

__END__

=head1 NAME

Plagger::Plugin::Notify::OpenBrowser::FirefoxRemote - Open updated entries in a browser

=head1 SYNOPSIS

  - module: Notify::OpenBrowser::FirefoxRemote

=head1 DESCRIPTION

This plugins opens updated entries in a remote Firefox using MozRepl
extension. You need to install MozRepl before running this plugin.
See L<http://dev.hyperstruct.net/trac/mozlab/wiki/MozRepl> for more.

=head1 CONFIG

=over 4

=item port

Port running Firefox MozRepl server. Defaults to 4242.

=back

=head1 TIPS

You should use SSH port forwarding if you'd like to connect remote
MozRepl instance.

=head1 AUTHOR

Tatsuhiko Miyagawa

youpy

=head1 SEE ALSO

L<Plagger>, L<Plagger::Plugin::Notify::OpenBrowser>

=cut
