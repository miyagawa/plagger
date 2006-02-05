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
    my @args  = $route->{host} ? ($route->{host}) : ();
    $msg->send($route->{via}, @args);
}

sub htmlize {
    my($self, $body) = @_;
    return <<HTML;
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
    }, \my $out) or die $tt->error;
    $out;
}

1;
