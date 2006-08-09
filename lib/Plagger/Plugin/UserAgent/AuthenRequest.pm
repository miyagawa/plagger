package Plagger::Plugin::UserAgent::AuthenRequest;
use strict;
use warnings;
use base qw/Plagger::Plugin/;

use LWP::UserAgent;
use List::Util qw/first/;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'useragent.request' => \&add_credentials,
    );
}

sub add_credentials {
    my($self, $context, $args) = @_;

    my $creds = $self->conf->{credentials} || [ $self->conf ];

    my $uri = URI->new($args->{url});
    for my $auth (grep { $_->{host} eq $uri->host_port } @$creds) {
        $context->log(info => "Adding credential to $auth->{realm} at $auth->{host}");
        $args->{ua}->credentials($auth->{host}, $auth->{realm}, $auth->{username}, $auth->{password});
    }
}

1;

__END__

=head1 NAME

Plagger::Plugin::UserAgent::AuthenRequest - Plagger plugin for authen request

=head1 SYNOPSYS

  - module: UserAgent::AuthenRequest
    config:
      host: example.com:80
      auth: basic
      realm: Security Area
      username: username
      password: password

=head1 DESCRIPTION

This plugin hooks Plagger::UserAgent fetch method to add username and
password to authenticated website. Since it hooks Plagger::UserAgent,
the config will be enabled in all plugins that uses Plagger::UserAgent
inside, e.g. from Aggregator::Simple to Publish::MT.

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=head1 SEE ALSO

L<Plagger>

=cut
