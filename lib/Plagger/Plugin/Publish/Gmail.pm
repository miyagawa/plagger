package Plagger::Plugin::Publish::Gmail;
use strict;
use base qw( Plagger::Plugin );

our $VERSION = '0.10';

use DateTime;
use DateTime::Format::Mail;
use Encode;
use Encode::MIME::Header;
use MIME::Lite;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'publish.notify' => \&notify,
    );
}

sub notify {
    my($self, $context, $feed) = @_;

    my @items = $feed->entries;
    if ($self->conf->{group_items}) {
        $self->send_email_feed($context, $feed, \@items);
    } else {
        for my $item (@items) {
            $self->send_email_item($context, $feed, $item);
        }
    }
}

sub send_email_feed {
    my($self, $context, $feed, $items) = @_;
    my $subject = $feed->title || '(no-title)';
    my $body = join '<hr />', map $self->templatize($context, $feed, $_), @$items;
    $self->do_send_mail($context, $feed, $subject, $body);
}

sub send_email_item {
    my($self, $context, $feed, $item) = @_;
    my $subject = $item->title || '(no-title)';
    my $body    = $self->templatize($context, $feed, $item);
    $self->do_send_mail($context, $feed, $subject, $body);
}

sub do_send_mail {
    my($self, $context, $feed, $subject, $body) = @_;

    $body = $self->htmlize($body);

    my $cfg = $self->conf;
    $context->log(warn => "Sending $subject to $cfg->{mailto}");

    my $feed_title = $feed->title;
       $feed_title =~ tr/,//d;

    my $now = Plagger::Date->now(timezone => $context->conf->{timezone});

    my $msg = MIME::Lite->new(
        Date => $now->format('Mail'),
        From => encode('MIME-Header', qq("$feed_title" <$cfg->{mailfrom}>)),
        To   => $cfg->{mailto},
        Subject => encode('MIME-Header', $subject),
        Type => 'multipart/related',
    );
    $msg->attach(
        Type => 'text/html; charset=utf-8',
        Data => encode("utf-8", $body),
    );

    my $route = $cfg->{mailroute} || { via => 'smtp', host => 'localhost' };
    if ($route->{via} eq 'smtp_tls') {
        $msg->send_by_smtp_tls(
            $route->{host},
            User     => $route->{username},
            Password => $route->{password},
        );
    } else {
        my @args  = $route->{host} ? ($route->{host}) : ();
        $msg->send($route->{via}, @args);
    }
}

sub htmlize {
    my($self, $body) = @_;
    return <<HTML;
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html;charset=utf-8" />
</head>
<body>
$body
</body>
</html>
HTML
}

sub templatize {
    my($self, $context, $feed, $item) = @_;
    my $tt = $context->template();
    $tt->process('gmail_notify.tt', {
        feed => $feed,
        item => $item,
        cfg  => $self->conf,
    }, \my $out) or $context->error($tt->error);
    $out;
}

# hack MIME::Lite to support TLS Authentication
package MIME::Lite;

sub send_by_smtp_tls {
    my($self, @args) = @_;

    ### We need the "From:" and "To:" headers to pass to the SMTP mailer:
    my $hdr  = $self->fields();
    my $from = $self->get('From');
    my $to   = $self->get('To');

    ### Sanity check:
    defined($to) or Carp::croak "send_by_smtp_tls: missing 'To:' address\n";

    ### Get the destinations as a simple array of addresses:
    my @to_all = extract_addrs($to);
    if ($MIME::Lite::AUTO_CC) {
        foreach my $field (qw(Cc Bcc)) {
            my $value = $self->get($field);
            push @to_all, extract_addrs($value) if defined($value);
        }
    }

    ### Create SMTP TLS client:
    require Net::SMTP::TLS;
    my $smtp = MIME::Lite::SMTP::TLS->new(@args)
        or Carp::croak("Failed to connect to mail server: $!\n");
    $smtp->mail($from);
    $smtp->to(@to_all);
    $smtp->data();

    ### MIME::Lite can print() to anything with a print() method:
    $self->print_for_smtp($smtp);
    $smtp->dataend();
    eval {
        local $SIG{__WARN__} = sub { };
        $smtp->quit;
    };

    # known error from Gmail SMTP
    if ($@ && $@ !~ /An error occurred disconnecting from the mail server/) {
        warn $@;
    }

    1;
}

package MIME::Lite::SMTP::TLS;
use base qw( Net::SMTP::TLS );

sub print { shift->datasend(@_) }

1;
