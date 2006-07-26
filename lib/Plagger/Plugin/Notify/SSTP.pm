package Plagger::Plugin::Notify::SSTP;
use strict;
use base qw( Plagger::Plugin );

our $VERSION = '0.0.1';

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
    my $title = $feed->title || '(no-title)';

    my @messages = $title;
    for my $entry ($args->{feed}->entries) {
        push @messages, $self->templatize('sstp.tt', { entry => $entry });
    }
    my $message = join '\x', @messages;
    $context->log(debug => $message);
    
    my $sstp = Plagger::Plugin::Notify::SSTP::Send->new(
        $self->conf->{host} || 'localhost',
        $self->conf->{port} || 9801,
        $self->conf->{options} || {},
    );
    my $result = $sstp->send($message);
    $context->log(debug => $result);
}

1;

package Plagger::Plugin::Notify::SSTP::Send;
use strict;
use IO::Socket::INET;
use Encode;

our $VERSION = '0.0.1';

our $SEND = 'SEND SSTP/1.4';
our $SENDER = 'Plagger::Plugin::SSTP::Send';
our $BREAK = "\r\n";

sub new {
    my $class = shift;
    my $host = shift || 'localhost';
    my $port = shift || 9801;
    my $options = shift || {};
    my $socket_options = {
        PeerAddr => $host,
        PeerPort => $port,
        Proto    => 'tcp',
        %$options,
    };
    bless {
        socket_options => $socket_options,
    }, $class;
}

sub socket {
    my $self = shift;
    IO::Socket::INET->new(%{$self->{socket_options}});
}

sub send {
    my $self = shift;
    my $str = shift;
    $str =~ s/\r?\n/\\n/go;
    utf8::decode($str) unless utf8::is_utf8($str);
    utf8::encode($str);

    $str .= "\\e";
    my $options = shift || {};
    my $send = {
        Sender => $SENDER,
        Script => $str,
        Charset => 'UTF-8',
        %$options,
    };
    my @result = $SEND;
    push @result, map {"$_: $send->{$_}"} keys %$send;
    push @result, '', '';
    my $result = join $BREAK, @result;
    my $socket = $self->socket;
    print $socket $result;
    $socket->flush;

    <$socket>;
}

1;

__END__

=head1 NAME

Plagger::Plugin::Notify::SSTP - Notify feed updates to SSTP

=head1 SYNOPSIS

  - module: Notify::SSTP
    config:
      host: 192.168.10.215 # default localhost
      port: 9821 # default 9801

=head1 DESCRIPTION

This plugin publish feed updates to SSTP(Sakura Script Transfer Protocol)

=head1 AUTHOR

Yuichi Tateno (id:secondlife)

=head1 SEE ALSO

L<Plagger>, L<IO::Socket::INET>

=cut
