package Plagger::Plugin::Publish::Gmail;
use strict;
use base qw( Plagger::Plugin );

our $VERSION = '0.10';

use DateTime;
use DateTime::Format::Mail;
use Encode;
use Encode::MIME::Header;
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

    my $feed = $args->{feed};
    my $subject = $feed->title || '(no-title)';
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

    for my $entry ($args->{feed}->entries) {
        for my $enclosure (grep $_->local_path, $entry->enclosures) {
            $msg->attach(
                Type => $enclosure->type,
                Path => $enclosure->local_path,
                Filename => $enclosure->filename,
                Disposition => 'attachment',
            );
        }
    }

    my $route = $cfg->{mailroute} || { via => 'smtp', host => 'localhost' };
    $route->{via} ||= 'smtp';

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
