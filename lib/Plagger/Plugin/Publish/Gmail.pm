package Plagger::Plugin::Publish::Gmail;
use strict;
use base qw( Plagger::Plugin );

our $VERSION = '0.10';

use DateTime;
use DateTime::Format::Mail;
use Encode;
use Encode::MIME::Header;
use HTML::Entities;
use HTML::Parser;
use MIME::Lite;

our %TLSConn;

sub rule_hook { 'publish.feed' }

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'publish.init' => \&initialize,
        'publish.feed' => \&notify,
    );
}

sub init {
    my $self = shift;
    $self->SUPER::init(@_);

    $self->conf->{mailto} or Plagger->context->error("mailto is required");
    $self->conf->{mailfrom} ||= 'plagger@localhost';
}

sub initialize {
    my($self,$context) = @_;

    # authenticate POP before SMTP
    if (my $conf = $self->conf->{pop3}) {
        require Net::POP3;
        my $pop = Net::POP3->new($conf->{host});
        if ($pop->login($conf->{username}, $conf->{password})) {
            $context->log(info => 'POP3 login succeed');
        } else {
            $context->log(error => 'POP3 login error');
        }
        $pop->quit;
    }
}

sub notify {
    my($self, $context, $args) = @_;

    return if $args->{feed}->count == 0;

    my $feed = $args->{feed};
    my $subject = $feed->title || '(no-title)';

    my @enclosure_cb;
    if ($self->conf->{attach_enclosures}) {
        for my $entry ($args->{feed}->entries) {
            push @enclosure_cb, $self->prepare_enclosures($entry);
        }
    }

    my $body = $self->templatize($context, $feed);

    my $cfg = $self->conf;
    $context->log(info => "Sending $subject to $cfg->{mailto}");

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
    $msg->replace("X-Mailer" => "Plagger/$Plagger::VERSION");

    $msg->attach(
        Type => 'text/html; charset=utf-8',
        Data => encode("utf-8", $body),
        Encoding => 'quoted-printable',
    );

    for my $cb (@enclosure_cb) {
        $cb->($msg);
    }

    my $route = $cfg->{mailroute} || { via => 'smtp', host => 'localhost' };
    $route->{via} ||= 'smtp';

    eval {
        if ($route->{via} eq 'smtp_tls') {
            $self->{tls_args} = [
                $route->{host},
                User     => $route->{username},
                Password => $route->{password},
                Port     => $route->{port} || 587,
            ];
            $msg->send_by_smtp_tls(@{ $self->{tls_args} });
        } elsif ($route->{via} eq 'sendmail') {
            my %param = (FromSender => "<$cfg->{mailfrom}>");
            $param{Sendmail} = $route->{command} if defined $route->{command};
            $msg->send('sendmail', %param);
        } else {
            my @args  = $route->{host} ? ($route->{host}) : ();
            $msg->send($route->{via}, @args);
        }
    };

    if ($@) {
        $context->log(error => "Error while sending emails: $@");
    }
}

sub prepare_enclosures {
    my($self, $entry) = @_;

    if (grep $_->is_inline, $entry->enclosures) {
        # replace inline enclosures to cid: entities
        my %url2enclosure = map { $_->url => $_ } $entry->enclosures;

        my $output;
        my $p = HTML::Parser->new(api_version => 3);
        $p->handler( default => sub { $output .= $_[0] }, "text" );
        $p->handler( start => sub {
                         my($tag, $attr, $attrseq, $text) = @_;
                         # TODO: use HTML::Tagset?
                         if (my $url = $attr->{src}) {
                             if (my $enclosure = $url2enclosure{$url}) {
                                 $attr->{src} = "cid:" . $self->enclosure_id($enclosure);
                             }
                             $output .= $self->generate_tag($tag, $attr, $attrseq);
                         } else {
                             $output .= $text;
                         }
                     }, "tag, attr, attrseq, text");
        $p->parse($entry->body);
        $p->eof;

        $entry->body($output);
    }

    return sub {
        my $msg = shift;

        for my $enclosure (grep $_->local_path, $entry->enclosures) {
            my %param = (
                Type => $enclosure->type,
                Path => $enclosure->local_path,
                Filename => $enclosure->filename,
            );

            if ($enclosure->is_inline) {
                $param{Id} = '<' . $self->enclosure_id($enclosure) . '>';
                $param{Disposition} = 'inline';
            } else {
                $param{Disposition} = 'attachment';
            }

            $msg->attach(%param);
        }
    }
}

sub generate_tag {
    my($self, $tag, $attr, $attrseq) = @_;

    return "<$tag " .
        join(' ', map { $_ eq '/' ? '/' : sprintf qq(%s="%s"), $_, encode_entities($attr->{$_}, q(<>"')) } @$attrseq) .
        '>';
}

sub enclosure_id {
    my($self, $enclosure) = @_;
    return Digest::MD5::md5_hex($enclosure->url->as_string) . '@Plagger';
}

sub templatize {
    my($self, $context, $feed) = @_;
    my $tt = $context->template();
    $tt->process('gmail_notify.tt', {
        feed => $feed,
    }, \my $out) or $context->error($tt->error);
    $out;
}

sub DESTORY {
    my $self = shift;
    return unless $self->{tls_args};

    my $conn_key = join "|", @{ $self->{tls_args} };
    eval {
        local $SIG{__WARN__} = sub { };
        $TLSConn{$conn_key} && $TLSConn{$conn_key}->quit;
    };

    # known error from Gmail SMTP
    if ($@ && $@ !~ /An error occurred disconnecting from the mail server/) {
        warn $@;
    }
}

# hack MIME::Lite to support TLS Authentication
*MIME::Lite::send_by_smtp_tls = sub {
    my($self, @args) = @_;

    ### We need the "From:" and "To:" headers to pass to the SMTP mailer:
    my $hdr   = $self->fields();
    my($from) = MIME::Lite::extract_addrs( $self->get('From') );
    my $to    = $self->get('To');

    ### Sanity check:
    defined($to) or Carp::croak "send_by_smtp_tls: missing 'To:' address\n";

    ### Get the destinations as a simple array of addresses:
    my @to_all = MIME::Lite::extract_addrs($to);
    if ($MIME::Lite::AUTO_CC) {
        foreach my $field (qw(Cc Bcc)) {
            my $value = $self->get($field);
            push @to_all, MIME::Lite::extract_addrs($value) if defined($value);
        }
    }

    ### Create SMTP TLS client:
    require Net::SMTP::TLS;

    my $conn_key = join "|", @args;
    my $smtp;
    unless ($smtp = $TLSConn{$conn_key}) {
        $smtp = $TLSConn{$conn_key} = MIME::Lite::SMTP::TLS->new(@args)
            or Carp::croak("Failed to connect to mail server: $!\n");
    }
    $smtp->mail($from);
    $smtp->to(@to_all);
    $smtp->data();

    ### MIME::Lite can print() to anything with a print() method:
    $self->print_for_smtp($smtp);
    $smtp->dataend();

    1;
};

@MIME::Lite::SMTP::TLS::ISA = qw( Net::SMTP::TLS );
sub MIME::Lite::SMTP::TLS::print { shift->datasend(@_) }

1;

__END__

=head1 NAME

Plagger::Plugin::Publish::Gmail - Notify updates to your email account

=head1 SYNOPSIS

  - module: Publish::Gmail
    config:
      mailto: example@gmail.com
      mailfrom: you@example.net

=head1 DESCRIPTION

This plugin creates HTML emails and sends them to your Gmail mailbox.

=head1 CONFIG

=over 4

=item mailto

Your email address to send updatess to. Required.

=item mailfrom

Email address to send email from. Defaults to I<plagger@localhost>.

=item mailroute

Hash to specify how to send emails. Defaults to:

  mailroute:
    via: smtp
    host: localhost

the value of I<via> would be either I<smtp>, I<smtp_tls> or I<sendmail>.

  mailroute:
    via: sendmail
    command: /usr/sbin/sendmail

=item attach_enclosures

Flag to attach enclosures as Email attachments. Defaults to 0.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<MIME::Lite>

=cut
