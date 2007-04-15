package Plagger::Plugin::Publish::Twitter;
use strict;
use base qw( Plagger::Plugin );

use Encode;
use Net::Twitter;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'publish.entry' => \&publish_entry,
        'plugin.init'   => \&initialize,
    );
}

sub initialize {
    my($self, $context) = @_;
    my %opt = (
        username => $self->conf->{username},
        password => $self->conf->{password},
    );
    for my $key (qw/ apihost apiurl apirealm/) {
        $opt{$key} = $self->conf->{$key} if $self->conf->{$key};
    }
    $self->{twitter} = Net::Twitter->new(%opt);
}

sub publish_entry {
    my($self, $context, $args) = @_;

    my $body = ( $args->{entry}->summary->plaintext || $args->{entry}->title ) . " " . $args->{entry}->permalink;
    # TODO: FIX when Summary configurable.
    if ( length($body) > 159 ) {
        $body = substr($body, 0, 159);
    }
    $context->log(info => "Updating Twitter status to '$body'");
    $self->{twitter}->update( encode_utf8($body) ) or $context->error("Can't update twitter status");
}

1;
__END__

=head1 NAME

Plagger::Plugin::Publish::Twitter - Update your status with feeds

=head1 SYNOPSIS

  - module: Publish::Twitter
    config:
      username: twitter-id
      password: twitter-password

=head1 DESCRIPTION

This plugin sends feed entries summary to your Twitter account status.

=head1 CONFIG

=over 4

=item username

Twitter username. Required.

=item password

Twitter password. Required.

=item apiurl

OPTIONAL. The URL of the API for twitter.com. This defaults to "http://twitter.com/statuses" if not set.

=item apihost

=item apirealm

Optional.
If you do point to a different URL, you will also need to set "apihost" and "apirealm" so that the internal LWP can authenticate.

    "apihost" defaults to "www.twitter.com:80".
    "apirealm" defaults to "Twitter API".

=back

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<Net::Twitter>

=cut
