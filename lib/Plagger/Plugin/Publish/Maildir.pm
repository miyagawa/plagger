package Plagger::Plugin::Publish::Maildir;
use strict;
use base qw( Plagger::Plugin );

use DateTime;
use DateTime::Format::Mail;
use Encode qw/ from_to encode/;
use Encode::MIME::Header;
use HTML::Entities;
use MIME::Lite;
use Digest::MD5 qw/ md5_hex /;;
use File::Find;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
      $self,
      'plugin.init'   => \&initialize,
      'publish.entry' => \&store_entry,
      'publish.finalize' => \&finalize,
    );
}

sub rule_hook { 'publish.entry' }

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
  my $body       = $self->templatize('mail.tt', $args);
     $body       = encode("utf-8", $body);
  my $from       = $cfg->{mailfrom} || 'plagger@localhost';
  my $id     = md5_hex($entry->id_safe);
  my $now = Plagger::Date->now(timezone => $context->conf->{timezone});
  my @enclosure_cb;
  if ($self->conf->{attach_enclosures}) {
      push @enclosure_cb, $self->prepare_enclosures($entry);
  }
  $msg = MIME::Lite->new(
    Date    => $now->format('Mail'),
    From    => encode('MIME-Header', qq("$feed_title" <$from>)),
    To      => $cfg->{mailto},
    Subject => encode('MIME-Header', $subject),
    Type    => 'multipart/related',
  );
  $msg->attach(
    Type => 'text/html; charset=utf-8',
    Data => $body,
    Encoding => 'quoted-printable',
  );
  for my $cb (@enclosure_cb) {
    $cb->($msg);
  }
  $msg->add('Message-Id', "<$id.plagger\@localhost>");
  $msg->add('X-Tags', encode('MIME-Header',join(' ',@{$entry->tags})));
  my $xmailer = "Plagger/$Plagger::VERSION";
  $msg->replace('X-Mailer',$xmailer);
  store_maildir($self, $context,$msg->as_string(),$id);
  $self->{msg} += 1;
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

sub store_maildir {
  my($self,$context,$msg,$id) = @_;
  my $filename = $id.".plagger";
  find(
    sub {
      if ($_ =~ m!$id.*!) {
        unlink $_;
        $self->{update_msg} += 1;
      }
    },
    $self->{path}."/cur"
  );
  $context->log(debug=> "writing: new/$filename");
  my $path = $self->{path}."/new/".$filename;
  open my $fh, ">", $path or $context->error("$path: $!");
  print $fh $msg;
  close $fh;
}

1;

=head1 NAME

Plagger::Plugin::Publish::Maildir - Store Maildir

=head1 SYNOPSIS

  - module: Publish::Maildir 
    config:
      maildir: /home/foo/Maildir
      folder: plagger
      attach_enclosures: 1
      mailfrom: plagger@localhost

=head1 DESCRIPTION

This plugin changes an entry into e-mail, and saves it to Maildir.

=head1 AUTHOR

Nobuhito Sato

=head1 SEE ALSO

L<Plagger>

=cut
