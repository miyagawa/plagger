package Plagger::Plugin::Publish::Maildir;
use strict;
use base qw( Plagger::Plugin );

use DateTime;
use DateTime::Format::Mail;
use Encode qw/ from_to encode/;
use Encode::MIME::Header;
use MIME::Lite;
use Digest::MD5 qw/ md5_hex /;;
use File::Find;

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
  my $permission = $cfg->{permission} || 0700;
  if (-d $cfg->{maildir}) {
    my $path = "$cfg->{maildir}/.$cfg->{folder}";
       $path =~ s/\/\//\//g;
       $path =~ s/\/$//g;
    unless (-d $path) {
      mkdir($path,0700)
        or die $context->log(error => "Could not create $path");
      $context->log(info => "Create new folder ($path)");
    }
    unless (-d $path."/new") {
      mkdir($path."/new",0700)
        or die $context->log(error => "Could not Create $path/new");
      $context->log(info => "Create new folder($path/new)");
    }
    $self->{path} = $path;
  }else{
    die $context->log(error => "Could not access $cfg->{maildir}");
  }
}

sub finalize {
  my ($self, $context, $args) = @_;
  if (my $msg_count = $self->{msg}) {
    if (my $update_count = $self->{update_msg}) {
      $context->log(info => "Store $msg_count message(s) ($update_count message(s) updated)");
    }else{
      $context->log(info => "Store $msg_count message(s)");
    }
  }
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
  my $from       = 'plagger@localhost';
  my $now = Plagger::Date->now(timezone => $context->conf->{timezone});
  $msg = MIME::Lite->new(
    Date    => $now->format('Mail'),
    From    => encode('MIME-Header', qq("$feed_title" <$from>)),
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
  my $filename = md5_hex($entry->id_safe);
  store_maildir($self, $context,$msg->as_string(),$filename);
  $self->{msg} += 1;
}

sub templatize {
  my ($self, $context, $args) = @_;
  my $tt = $context->template();
#  $tt->process( 'gmail_notify.tt', {
  $tt->process( 'mail.tt', {
    entry => $args->{entry},
    feed  => $args->{feed},
  }, \my $out ) or $context->error($tt->error);
  $out;
}

sub store_maildir {
  my($self,$context,$msg,$file) = @_;
  my $filename = $file.".plagger";
  find(
    sub {
      if ($_ =~ m!$file.*!) {
        unlink $_;
        $self->{update_msg} += 1;
      }
    },
    $self->{path}."/cur"
  );
  my $filename = $self->{path}."/new/".$filename;
  open(FILE,">$filename");
  print(FILE $msg);
  close(FILE);
}

1;

=head1 NAME

Plagger::Plugin::Publish::Maildir - Store Maildir

=head1 SYNOPSIS

  - module: Publish::Maildir 
    config:
      maildir: /home/foo/Maildir
      folder: plagger

=head1 DESCRIPTION

This plugin changes an entry into e-mail, and saves it to Maildir.

=head1 AUTHOR

Nobuhito Sato

=head1 SEE ALSO

L<Plagger>

=cut
