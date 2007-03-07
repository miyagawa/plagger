package Plagger::Plugin::Publish::Twitter;
use strict;
use base qw( Plagger::Plugin );

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
    $self->{twitter} = Net::Twitter->new(
        username => $self->conf->{username},
        password => $self->conf->{password},
    );
}

sub publish_entry {
    my($self, $context, $args) = @_;

    my $body = ( $args->{entry}->summary || $args->{entry}->title ) . " " . $args->{entry}->permalink;
    $context->log(info => "Updating Twitter status to '$body'");
    $self->{twitter}->update($body);
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

=back

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<Net::Twitter>

=cut
