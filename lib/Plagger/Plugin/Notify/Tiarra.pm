package Plagger::Plugin::Notify::Tiarra;
use strict;
use base qw( Plagger::Plugin );

use Encode;
use IO::Socket::UNIX;
use Time::HiRes;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'publish.feed' => \&update,
    );
}

sub update {
    my($self, $context, $args) = @_;

    $context->log(info => "Notifying " . $args->{feed}->title . " to IRC");

    my $protocol = 'TIARRACONTROL/1.0';

    my $request_template = <<END;
NOTIFY System::SendMessage [% protocol %]\r
Sender: [% sender %]\r
Notice: [% use_notice %]\r
Channel: [% channel %]\r
Charset: [% charset %]\r
Text: [% text %]\r
\r
END

    # be able to set charset except UTF-8,
    # but anyway Tiarra processing message with UTF-8.
    my $charset = $self->conf->{charset} || 'UTF-8';

    my $body = $self->templatize('irc_notify.tt', $args);

    for my $line (split("\n", $body)) {
	my $remote = IO::Socket::UNIX->new(
	    Type => SOCK_STREAM,
	    Peer => '/tmp/tiarra-control/' . $self->conf->{socketname},
	   );

	unless ($remote) {
	    $context->log(error => "cannot open sock: $!");
	    return;
	}

	my $out = $self->templatize(\$request_template, {
	    protocol => $protocol,
	    charset  => $charset,
	    channel  => $self->conf->{channel},
	    sender   => $self->conf->{sender} || "Plagger/$Plagger::VERSION (http://plagger.bulknews.net/)",
	    use_notice => ($self->conf->{use_notice} ? 'yes' : 'no'),
	    text     => $line,
	});
	Encode::_utf8_off($out) if Encode::is_utf8($out);
	Encode::from_to($out, 'utf-8', $charset) unless uc($charset) eq 'UTF-8';
	$remote->print($out);

	my $resp = <$remote>;
	if ($resp !~ /$protocol 200 OK/) {
	    $context->log(error => $resp);
	}

	$remote->close;
	Time::HiRes::sleep( $self->conf->{send_interval} || 2 );
    }
}

1;

__END__

=head1 NAME

Plagger::Plugin::Notify::Tiarra - Notify feed updates to Tiraa IRC Proxy

=head1 SYNOPSIS

  - module: Notify::Tiarra
    config:
      socketname: foobar
      channel: #plagger-test
      use_notice: 1

=head1 DESCRIPTION

This plugin allows you to notify feed updates to IRC channels using
Tiarra IRC Proxy. This module uses Tiarra ControlPort feature and
System::SendMessage module to send notify.

=head1 AUTHOR

Tatsuya Noda

This module is based on Plagger::Plugin::Notify::IRC.

=head1 SEE ALSO

L<Plagger>, L<Plagger::Plugin::Notify::IRC>

=cut

