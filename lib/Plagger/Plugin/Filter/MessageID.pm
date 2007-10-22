package Plagger::Plugin::Filter::MessageID;
use strict;
use base qw( Plagger::Plugin );

use Plagger::Util;

sub register {
    my ($self, $context) = @_;
    $context->register_hook(
        $self,
        'update.feed.fixup'  => \&feed,
        'plugin.init'        => \&initialize,
    );
}

sub initialize {
    my($self, $context, $args) = @_;

    unless ($self->conf->{domain}) { 
        $self->conf->{domain} = do {
            require Net::Domain;
            Net::Domain::hostfqdn();
        };
    }
}

sub feed {
    my($self, $context, $args) = @_;

    my $feed = $args->{feed};
    my $mes_id;
    my @id_digest;
    my $domain = $self->conf->{domain};

    for my $entry ($feed->entries) {
        my $entry_id_digest = ($entry->id .':'. $entry->digest);
        push @id_digest, $entry_id_digest;
        $context->log(debug => "MessageID seed: $entry_id_digest");
    }

    $mes_id = '<' . $feed->id_safe .'_'
        . Plagger::Util::safe_id( join(' ', @id_digest) ) .'@'. $domain .'>';
    $feed->{meta}->{messageid} = $mes_id;
    $context->log(info => 'set '. $feed->link ." MessageID: $mes_id");
}

1;
__END__

=head1 NAME

Plagger::Plugin::Filter::MessageID - set Message-ID at Feed

=head1 SYNOPSIS

  - module: Filter::MessageID
    config:
      domain: plagger.example.com

=head1 DESCRIPTION

This plugin generate Message-ID from id and digest of all Entries in Feed.
You can use it in $args->{feed}->{meta}->{messageid}.

=head1 CONFIG

=over 4

=item domain

set domain part of Message-ID. (optional)
see RFC 2822 "3.6.4. Identification fields".

=head1 AUTHOR

Masafumi Otsune

=head1 SEE ALSO

L<Plagger>, L<http://www.ietf.org/rfc/rfc2822.txt>

=cut
