package Plagger::Plugin::Server::Protocol::SMTP;
use strict;

use base qw(Plagger::Plugin::Server::Protocol );
__PACKAGE__->mk_accessors( qw(mail_from rcpt_to body qid) );

use HTTP::Date;

sub proto { 'tcp' }
sub service { 'smtp' }

sub session_init {
    my $self = shift;

    $self->status(0);
    $self->mail_from('');
    $self->rcpt_to('');
    $self->body('');
    $self->qid('');
}

sub input {
    my $self = shift;
    my $req = shift;

    printf("220 %s SMTP Plagger %s; %s\r\n", $self->conf->{host}, $Plagger::VERSION, HTTP::Date::time2str);

    my $data_mode = 0;
    my $data;
    while (<STDIN>) {
        Plagger->context->log(debug => "request: " . $_);

        if ($data_mode) {
        Plagger->context->log(debug => "request DATA: " . $_);
            if (/^\.\r\n$/) {
        Plagger->context->log(debug => "request DATA END: " . $_);
                $self->body($data);
                $self->qid(sprintf("%d.%d.%d", $$, time, int(rand(10000))));
                printf("250 2.0.0 %s Message accepted for delivery\r\n", $self->qid);
                $data_mode = 0;
                next;
            }
            s/^\.\./\./;
            $data .= $_;
            next;
        }
        if (/^HELO (.+)\r\n$/i) {
            my $host = $1;
            $host =~ s/[^\w\d\-\_\.]//g;
            printf("250 %s Hello %s [%s] (may be forged), pleased to meet you\r\n", $self->conf->{host}, $host, $host);
        } elsif (/^MAIL FROM:(.+)\r\n$/i) {
            $self->mail_from($1);
            printf("250 2.1.0 %s... Sender ok\r\n", $self->mail_from);
        } elsif (/^RCPT TO:(.+)\r\n$/i) {
            $self->rcpt_to($1);
            printf("250 2.1.5 %s... Recipient ok\r\n", $self->rcpt_to);
        } elsif (/^DATA.*\r\n$/i) {
            print "354 Enter mail, end with "." on a line by itself\r\n";
            $data_mode = 1;
        } elsif (/^QUIT.*\r\n$/i) {
            printf("221 2.0.0 %s closing connection\r\n", $self->conf->{host});
            last;
        } else {
            print "500 5.5.1 Command unrecognized: $_";
        }
    }
    return 0 unless $self->mail_from && $self->rcpt_to && $self->body;
    return 1;
}

1;
