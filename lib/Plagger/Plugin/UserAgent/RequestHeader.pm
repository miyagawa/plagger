package Plagger::Plugin::UserAgent::RequestHeader;
use strict;
use warnings;
use base qw( Plagger::Plugin );

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'useragent.request' => \&add_header,
    );
}

sub add_header {
    my($self, $context, $args) = @_;

    for my $header (keys %{ $self->conf }) {
        $args->{ua}->default_header( $header => $self->conf->{$header} );
    }
}

1;

__END__

=head1 NAME

Plagger::Plugin::UserAgent::RequestHeader - Add arbitrary request header

=head1 SYNOPSIS

  - module: UserAgent::RequestHeader
    config:
      Accept-Language: ja, en

=head1 DESCRIPTION

This plugin hooks Plagger::UserAgent request method to add arbitrary
request header when HTTP request is sent.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<LWP::UserAgent>

=cut
