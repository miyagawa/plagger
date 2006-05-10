package Plagger::Plugin::Server::Pull::POP3;
use strict;
use base qw( Plagger::Plugin::Server::Pull );

use DateTime;
use DateTime::Format::Mail;
use Digest::MD5 qw(md5_hex);
use Encode;
use Encode::MIME::Header;
use MIME::Lite;

sub register {
    my($self, $context) = @_;

    $context->register_hook(
        $self,
        'pull.finalize' => \&finalize,
        'protocol.pop3.command' => \&command,
    );
}

sub dispatch_rule_on { 1 }

sub finalize {
    my($self, $context, $args) = @_;

    $context->log(debug => "finalize.");

    my $list = {};
    my $size = 0;
    my $num = 0;
    for my $feed ($context->update->feeds) {
        for my $entry ($feed->entries) {
            my $body = $self->gen_mail($context, { feed => $feed, entry => $entry });
            $num++;
            $list->{$num} = {
                feed  => $feed,
                entry => $entry,
                body  => $body,
                size  => length($body),
                dele  => 0,
            };
            $size += length($body);
        }
    }

    $self->{list} = $list;
    $self->{size} = $size;
    $self->{num}  = $num;
    $self->{_size} = $size;
    $self->{_num}  = $num;

    while (!$args->{req}->protocol->quit) {
        $context->run_hook_once('protocol.pop3.recv');
    }
}

sub command {
    my($self, $context, $args) = @_;

    my $command = sprintf("cmd_%s", uc($args->{args}->[0]));
    $context->log(debug => "command: $command");

    my $data;
    if (!$args->{req}->protocol->authed && $command !~ /^cmd_(USER|PASS|APOP|QUIT)$/) {
        $data = "-ERR authorization first\r\n";
    } elsif ($self->can($command)) {
        $data = $self->$command($context, $args);
    } else {
        $data = "-ERR unknown command\r\n";
    }

    if ($data) {
        $context->run_hook_once('protocol.pop3.send', { data => $data } );
    }
}

sub cmd_USER {
    my($self, $context, $args) = @_;
    my $pop3 = $args->{req}->protocol;
    return "+OK\r\n" if $pop3->authed;

    $pop3->user($args->{args}->[1]);
    return "+OK please send PASS command\r\n";
}

sub cmd_PASS {
    my($self, $context, $args) = @_;
    my $pop3 = $args->{req}->protocol;
    return "+OK\r\n" if $pop3->authed;

    $pop3->pass($args->{args}->[1]);
    unless ($pop3->conf->{user} eq $pop3->user && $pop3->conf->{password} eq $pop3->pass) {
        $pop3->status(1);
        $pop3->quit(1);
        return "-ERR authorization failed\r\n";
    }

    $pop3->authed(1);
    return sprintf("+OK %s welcome here\r\n", $pop3->user);
}

sub cmd_APOP {
    my($self, $context, $args) = @_;
    my $pop3 = $args->{req}->protocol;
    return "+OK\r\n" if $pop3->authed;

    $pop3->user($args->{args}->[1]);
    $pop3->pass($args->{args}->[2]);
    my $pass = md5_hex($pop3->apopkey.$pop3->conf->{password});
    unless ($pop3->conf->{user} eq $pop3->user && $pass eq $pop3->pass) {
        $pop3->status(1);
        $pop3->quit(1);
        return "-ERR authorization failed\r\n";
    }

    $pop3->authed(1);
    return sprintf("+OK %s welcome here\r\n", $pop3->user);
}

sub cmd_STAT {
    my($self, $context, $args) = @_;
    return sprintf("+OK %d %d\r\n", $self->{num}, $self->{size});
}

sub cmd_LIST {
    my($self, $context, $args) = @_;

    my $data;
    my $vid = $args->{args}->[1];
    my $list = $self->{list};
    if ($vid && $list->{$vid}) {
        $data = "+OK 1 messages\r\n";
        $data .= sprintf("%d %d\r\n", $vid, $list->{$vid}->{size});
    } else {
        $data = sprintf("+OK %d messages\r\n", $self->{num});
        for (my $id = 1;$id <= $self->{num};$id++) {
            next if $list->{$id}->{dele};
            $data .= sprintf("%d %d\r\n", $id, $list->{$id}->{size});
        }
    } 
    $data .= ".\r\n";

    return $data;
}

sub cmd_UIDL {
    my($self, $context, $args) = @_;

    my $data;
    my $vid = $args->{args}->[1];
    my $list = $self->{list};
    if ($vid && $list->{$vid}) {
        $data = "+OK 1 messages\r\n";
        $data .= sprintf("%d %d\r\n", $vid, $list->{$vid}->{size});
    } else {
        $data = sprintf("+OK %d messages\r\n", $self->{num});
        for (my $id = 1;$id <= $self->{num};$id++) {
            next if $list->{$id}->{dele};
            $data .= sprintf("%d <%s\@%s>\r\n", $id, md5_hex($list->{$id}->{entry}->id_safe), md5_hex($list->{$id}->{feed}->id));
        }
    }
    $data .= ".\r\n";

    return $data;
}

sub cmd_RETR {
    my($self, $context, $args) = @_;

    my $vid = $args->{args}->[1];
    my $body = $self->{list}->{$vid}->{body};
    $body .= "\r\n" if $body && $body !~ /\n$/;
    $body = sprintf("+OK %d octets\r\n%s", length($body), $body);
    $body .= ".\r\n";

    return $body;
}

sub cmd_TOP {
    my($self, $context, $args) = @_;

    my($head, $body) = $self->{list}->{$args->{args}->[1]}->{body} =~ /^(.+?)\r\n\r\n(.*)$/mso;
    my @bodys = split(/\r\n/, $body);
    $head .= "\r\n\r\n" if $args->{args}->[2];
    $body = "$head" . join("\r\n", splice(@bodys, 0, $args->{args}->[2]));

    $body .= "\r\n" if $body && $body !~ /\n$/;
    $body = sprintf("+OK %d octets\r\n%s", length($body), $body);
    $body .= ".\r\n";

    return $body;
}

sub cmd_DELE {
    my($self, $context, $args) = @_;

    my $vid = $args->{args}->[1];
    if ($self->{list}->{$vid} && !$self->{list}->{$vid}->{dele}) {
        $self->{list}->{$vid}->{dele} = 1;
        $self->{num}--;
        $self->{size} -= $self->{list}->{$vid}->{size};
    }

    return "+OK\r\n";
}

sub cmd_RSET {
    my($self, $context, $args) = @_;

    $self->{size} = $self->{_size};
    $self->{num}  = $self->{_num};
    for (my $id = 1;$id <= $self->{num};$id++) {
        $self->{list}->{$id}->{dele} = 0;
    }

    return "+OK\r\n";
}

sub cmd_NOOP {
    my($self, $context, $args) = @_;
    return "+OK\r\n";
}

sub cmd_QUIT {
    my($self, $context, $args) = @_;
    $args->{req}->protocol->quit(1);
    return '';
}

sub gen_mail {
    my($self, $context, $args) = @_;

    my $feed = $args->{feed};
    my $entry = $args->{entry};
    my $subject = $entry->title || '(no-title)';
    my $body = $self->templatize($context, { feed => $feed, entry => $entry });;

    my $feed_title = $feed->title;
       $feed_title =~ tr/,//d;

    my $now = $entry->date || Plagger::Date->now(timezone => $context->conf->{timezone});

    my $msg = MIME::Lite->new(
        Date => $now->format('Mail'),
        From => encode('MIME-Header', sprintf(qq("%s" <%s>), $feed_title, $entry->author || $feed->author || '')),
        Subject => encode('MIME-Header', $subject),
        Type => 'multipart/related',
        'X-Feed-Link' => $feed->link,
        'X-Entry-Link' => $entry->permalink,
        'Message-Id' => sprintf("<%s@%s>", md5_hex($entry->id_safe), md5_hex($feed->id)),
    );
    $msg->replace("X-Mailer" => "Plagger/$Plagger::VERSION");

    $msg->attach(
        Type => 'text/html; charset=utf-8',
        Data => encode("utf-8", $body),
    );

    my $msg = $msg->as_string;
    $msg =~ s/\n/\r\n/g if $msg =~ /\n\n/;
    $msg;
}

sub templatize {
    my($self, $context, $opt) = @_;
    my $tt = $context->template();
    $tt->process('mail.tt', $opt, \my $out) or $context->error($tt->error);
    $out;
}

1;
