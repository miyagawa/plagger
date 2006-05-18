package Plagger::Plugin::Subscription::XOXO;
use strict;
use base qw( Plagger::Plugin::Subscription::XPath );

sub load {
    my($self, $context) = @_;

    $self->conf->{xpath} = '//ul[@class="xoxo" or @class="subscriptionlist"]//a';
    $self->SUPER::load($context);
}

1;

__END__

=head1 NAME

Plagger::Plugin::Subscription::XOXO - Subscription list with XOXO microformats

=head1 SYNOPSIS

  - module: Subscription::XOXO
    config:
      url: http://example.com/mySubscriptions.xhtml

=head1 DESCRIPTION

This plugin creates Subscription by fetching remote XOXO file by HTTP
or locally (with C<file://> URI). The parser is implemented in really
a dumb way and only supports extracting URL (I<href>) and title from A
links inside XOXO C<ul> or C<ol> tags.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<http://microformats.org/wiki/xoxo>

=cut
