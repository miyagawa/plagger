package Plagger::Plugin::Publish::IMAP;
use strict;
use base qw( Plagger::Plugin );

use DateTime;
use DateTime::Format::Mail;
use Encode qw/ from_to encode/;
use Encode::MIME::Header;
use MIME::Lite;
use IO::File;
use Mail::IMAPClient;
use Digest::MD5 qw/ md5_hex /;;

sub register {
    my($self, $context) = @_;
    $self->{version} = '0.1';
    $context->register_hook(
      $self,
      'publish.init' => \&initialize,
      'publish.entry.fixup' => \&store_entry,
      'publish.finalize' => \&finalize,
    );
}

sub initialize {
  my ($self, $context, $args) = @_;
  my $cfg = $self->conf;
  $self->{imap} = Mail::IMAPClient->new(
    User     => $cfg->{username},
    Password => $cfg->{password},
    Server   => $cfg->{host} || 'localhost',
    Port     => $cfg->{port} || 143,
  ) or die $context->log(error => "Cannot connect; $@");
  $context->log(debug => "Connected IMAP-SERVER (".$cfg->{host}.")");
  if ($cfg->{folder} && !$self->{imap}->exists($cfg->{folder})) {
    $self->{imap}->create($cfg->{folder})
      or die $context->log(error => "Could not create $cfg->{folder}: $@");
    $context->log(info => "Create new folder ($cfg->{folder})");
  }
  if (!$cfg->{mailfrom}) {
    $cfg->{mailfrom} = 'plagger';
  }
}

sub finalize {
  my ($self, $context, $args) = @_;
  my $cfg  = $self->{conf};
  $self->{imap}->disconnect();
  if (my $msg_count = $self->{msg}) {
    $context->log(info => "Store $msg_count Message(s)");
  }
  $context->log(debug => "Disconnected IMAP-SERVER (".$cfg->{host}.")");
}

sub store_entry {
  my($self, $context, $args) = @_;
  my $cfg = $self->conf;
  my $msg;
  my $entry = $args->{entry}; 
  my $feed_title = $args->{feed}->title;
     $feed_title =~ tr/,//d;
  my $subject    = $entry->title || '(no-title)';
  my $body       = $self->templatize($context, $args);
  my $now = Plagger::Date->now(timezone => $context->conf->{timezone});
  $msg = MIME::Lite->new(
    Date    => $now->format('Mail'),
    From    => encode('MIME-Header', qq("$feed_title" <$cfg->{mailfrom}>)),
    To      => $cfg->{mailto},
    Subject => encode('MIME-Header', $subject),
    Type    => 'multipart/related',
  );
  $body = encode("utf-8", $body);
  $msg->attach(
    Type => 'text/html; charset=utf-8',
    Data => $body,
  );
  $msg->add('X-Tags', encode('MIME-Header',join(' ',@{$entry->tags})));
  my $xmailer = "MIME::Lite (Publish::Maildir Ver.$self->{version} in plagger)";
  $msg->replace('X-Mailer',$xmailer);
  $msg->add('In-Reply-To',"<".md5_hex($entry->id_safe).'@localhost>');
  store_maildir($self, $context,$msg->as_string());
  $self->{msg} += 1;
}

sub templatize {
  my ($self, $context, $args) = @_;
  my $tt = $context->template();
  $tt->process( 'mail.tt', {
    entry => $args->{entry},
    feed  => $args->{feed},
  }, \my $out ) or $context->error($tt->error);
  $out;
}

sub store_maildir {
  my($self,$context,$msg) = @_;
  my $folder = $self->conf->{folder} || 'INBOX';
  my $uid = $self->{imap}->append_string($folder,$msg)
    or die $context->log(error => "Could not append: $@");
}

1;
