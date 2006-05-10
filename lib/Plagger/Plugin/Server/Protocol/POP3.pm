package Plagger::Plugin::Server::Protocol::POP3;
use strict;

use base qw(Plagger::Plugin::Server::Protocol );
__PACKAGE__->mk_accessors( qw(user pass apopkey authed quit req) );

sub register {
    my($self, $context) = @_;

    $context->protocol->add_protocol($self);
    $context->register_hook(
        $self,
        'protocol.pop3.recv' => \&recv,
        'protocol.pop3.send' => \&send,
    );
}

sub proto { 'tcp' }
sub service { 'pop3' }

sub session_init {
    my $self = shift;

    $self->status(0);
    $self->body('');
    $self->user('');
    $self->pass('');
    $self->apopkey('');
    $self->authed('');
    $self->quit(0);
    $self->req('');
}

sub get_line {
    my $self = shift;
    my $ret = <STDIN>;
    Plagger->context->log(debug => "request: " . $ret);
    $ret;
}

sub input {
    my $self = shift;
    $self->req(shift);

    $self->apopkey(sprintf("<%d.%d.%d\@%s>", time, $$, int(rand(100000)), $self->conf->{host}));
    printf("+OK Plagger/%s server ready. %s\r\n", $Plagger::VERSION, $self->apopkey);

    while (!$self->quit && !$self->authed) {
        Plagger::context->run_hook_once('protocol.pop3.recv');
    }
    return 0 if $self->quit;
    return 1;
}

sub output { print "+OK quit\r\n" }

sub recv {
    my($self, $context, $args) = @_;

    $context->log(debug => "recv.");

    my $recv = $self->get_line;
    unless ($recv) {
        $self->quit(1);
        return;
    }

    $recv =~ s/[\r\n]+$//;
    my @args = split(/ /, $recv);
    $context->run_hook_once('protocol.pop3.command', { args => \@args, req => $self->req });
}

sub send {
    my($self, $context, $args) = @_;
    $context->log(debug => "send.");
    print $args->{data};
}

1;
