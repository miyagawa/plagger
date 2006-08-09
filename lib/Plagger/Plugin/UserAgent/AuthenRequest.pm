package Plagger::Plugin::UserAgent::AuthenRequest;
use strict;
use warnings;
use base qw/Plagger::Plugin/;

use LWP::UserAgent;
use List::Util qw/first/;

sub new {
    my $self = shift->SUPER::new(@_);

    $self->inject;

    $self;
}

sub register {}

sub inject {
    my $self = shift;

    {
        no warnings 'redefine';

        *LWP::UserAgent::__request__ = \&LWP::UserAgent::request;
        *LWP::UserAgent::request = sub {
            my $agent = shift;
            my $req   = shift;

            my $auth = first { $req->uri =~ /$_/ } keys %{ $self->conf };
            $auth = $self->conf->{$auth};

            if ( $auth && $auth->{auth} eq 'basic' ) { # todo: other authentication support
                $req->headers->authorization_basic( $auth->{username}, $auth->{password} );
            }

            $agent->__request__( $req, @_ );
        };
    }
}

1;

__END__

=head1 NAME

Plagger::Plugin::UserAgent::AuthenRequest - Plagger plugin for authen request

=head1 SYNOPSYS

  - module: UserAgent::AuthenRequest
    config:
      '^http://example.com/':
        auth: basic
        username: username
        password: password

=head1 DESCRIPTION

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=head1 SEE ALSO

L<Plagger>

=cut
