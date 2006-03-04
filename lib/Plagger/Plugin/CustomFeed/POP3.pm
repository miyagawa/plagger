package Plagger::Plugin::CustomFeed::POP3;
use strict;
use base qw( Plagger::Plugin );

use Net::POP3;
use Encode;
use HTML::Entities qw/encode_entities/;
use Email::MIME;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'subscription.load' => \&load,
        'aggregator.aggregate.pop3' => \&aggregate,
    );
}

sub load {
    my($self, $context) = @_;

    my $feed = Plagger::Feed->new;
       $feed->type('pop3');
    $context->subscription->add($feed);
}

sub aggregate {
    my($self, $context, $args) = @_;

    my $host = $self->conf->{host};
    my $pop = Net::POP3->new($host);

    unless ($pop->login($self->conf->{username}, $self->conf->{password})) {
        $context->log(error => "Login to $host failed.");
        return;
    }

    $context->log(info => "Login to pop3 server($host) succeeded.");

    my $msgnums = $pop->list;
    for my $msgnum (keys %$msgnums) {
        $context->log(debug => "get the message : $msgnum");

        my $msg = $pop->get($msgnum);
        my $feed = $self->mail2feed(join '', @$msg);
        $context->update->add($feed);

        if ($self->conf->{delete}) {
            $context->log(info => "delete message : $msgnum");
            $pop->delete($msgnum)
        }
    }

    $pop->quit;
}

sub mail2feed {
    my ($self, $message) = @_;

    my $entry  = Plagger::Entry->new;
    my $email  = Email::MIME->new($message);
    my $format = DateTime::Format::Mail->new->loose;

    my $feed = Plagger::Feed->new;
    $feed->type('pop3');
    $feed->title($email->header('Subject'));

    $entry->title($email->header('Subject'));
    $entry->author($email->header('From'));
    $entry->date(Plagger::Date->parse($format, $email->header('Date'))) if $email->header('Date');
    $entry->body($self->get_body($email));

    $feed->add_entry($entry);

    return $feed;
}

sub get_body {
    my ($self, $email) = @_;

    my $body_part;
    for my $part ($email->parts) {
        if ($part->content_type =~ m[text/html] or ($part->content_type =~ m[text/plain] and !$body_part)) {
            $body_part = $part;
        }
    }
    $body_part ||= $email;

    $body_part->content_type =~  /charset=(['"]?)([\w-]+)\1/;
    my $encoding = $2 || 'utf-8';

    if ($body_part->content_type =~ m[text/html]) {
        return decode($encoding, $body_part->body);
    } else {
        return '<pre>'.encode_entities(decode($encoding, $body_part->body)).'</pre>';
    }
}

1;
__END__

=head1 NAME

Plagger::Plugin::CustomFeed::POP3 - Custom feed for POP3

=head1 SYNOPSIS

  - module: CustomFeed::POP3
    config:
        host: example.com
        username: tokuhirom
        password: PASSW0RD
        #delete: 1

=head1 TODO
     support $entry->enclosures

=head1 AUTHOR

Tokuhiro Matsuno <tokuhiro at mobilefactory.jp>

=head1 SEE ALSO

L<Plagger>

=cut
