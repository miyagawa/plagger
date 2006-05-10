package Plagger::Plugin::Server::Engine::PreFork;
use strict;
use base qw( Plagger::Plugin::Server::Engine Net::Server::PreFork );

use Plagger::Server::Request;

sub register {
    my($self, $context) = @_;

    $self->context($context);
    $context->register_hook(
        $self,
        'engine.load' => \&load,
        'engine.run' => \&start,
    );
}

sub load {
    my($self, $context) = @_;

    $self->log(debug => "load.");
}

sub start {
    my $self = shift;
    $self->log(debug => "start.");

    my @port = map{ (port => sprintf('%s:%s|%s', $_->conf->{host}, $_->conf->{port}, $_->proto)) }
        $self->{context}->protocol->protocols;
    $self->run(@port);
}

sub configure_hook {
    my $self = shift;
    $self->log(debug => "configure_hook.");

    $self->{server}->{user} = $<;
    $self->{server}->{group} = $(;

    # TODO set to the Net::Server config
}

# Net::Server hook
sub process_request {
    my $self = shift;
    $self->log(debug => "process_request.");

    my $server = $self->{server};
    my $use_protocol;
    foreach my $protocol ($self->context->protocol->protocols) {
        if ($server->{proto} eq $protocol->proto &&
            $server->{sockport} eq $protocol->conf->{port} &&
            $server->{sockaddr} eq $protocol->conf->{host}) {
            $self->log(debug => "input.");

            $protocol->session_init;
            $use_protocol = $protocol;
            my $req = Plagger::Server::Request->new(protocol => $protocol, server => $server);
            next unless $protocol->input($req);
            $self->context->engine_run($req);
            last;
        }
    }
    $self->log(debug => "output.");
    $use_protocol->output if $use_protocol
}

1;
