package Plagger::Plugin::Publish::Twitter;
use strict;
use base qw( Plagger::Plugin );

use Encode;
use Net::Twitter;
use Time::HiRes qw(sleep);

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
        traits   => ['API::REST', 'OAuth'], 
        username => $self->conf->{username},
        password => $self->conf->{password},
    );
    for my $key (qw/apihost apiurl apirealm consumer_key consumer_secret/) {
        $opt{$key} = $self->conf->{$key} if $self->conf->{$key};
    }
    my $nettwitter = Net::Twitter->new(%opt);
    if ($self->conf->{access_token} and $self->conf->{access_token_secret}) {
        $nettwitter->access_token($self->conf->{access_token});
        $nettwitter->access_token_secret($self->conf->{access_token_secret});
    }
    $self->{twitter} = $nettwitter;
}

sub publish_entry {
    my($self, $context, $args) = @_;
    my $body = $args->{entry}->body_text;

    if ($self->conf->{templatize}) {
	$body = $self->templatize('twitter.tt', $args);
    }

    my $maxlength = $self->conf->{maxlength} || 159;
    if (length($body) > $maxlength) {
        $body = substr($body, 0, $maxlength);
    }

    if ($Net::Twitter::VERSION < '3.00000') {
	$body = encode_utf8( $body );
    }

    $context->log(info => "Updating Twitter status to '$body'");
    $self->{twitter}->update( $body ) or $context->error("Can't update twitter status");

    my $sleeping_time = $self->conf->{interval} || 15;
    $context->log(info => "sleep $sleeping_time.");
    sleep( $sleeping_time );
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

=item interval

Optional.

=item maxlength

Optional. defaults is 159. (backward compatibility)

=item apiurl

OPTIONAL. The URL of the API for twitter.com. This defaults to "http://twitter.com/statuses" if not set.

=item apihost

=item apirealm

Optional.
If you do point to a different URL, you will also need to set "apihost" and "apirealm" so that the internal LWP can authenticate.

    "apihost" defaults to "www.twitter.com:80".
    "apirealm" defaults to "Twitter API".

=item templatize
Optional.
A flag to use Template-Toolkit to message formatting. Defaults to 0.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<Net::Twitter>

=cut
