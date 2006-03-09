package Plagger::Plugin::Filter::Emoticon;
use strict;
use warnings;
use base qw( Plagger::Plugin );

our $VERSION = 0.01;

use Text::Emoticon;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'update.entry.fixup' => \&filter,
    );
}

sub filter {
    my($self, $context, $args) = @_;
    my $entry = $args->{entry};
    my $emoticon = Text::Emoticon->new(
        $self->conf->{driver} || 'MSN',
        $self->conf->{option} || {},
    );
    $entry->body($emoticon->filter($entry->body));
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::Emoticon - Emoticon Filter

=head1 SYNOPSIS

  - module: Filter::Emoticon
    config:
      driver: Yahoo
    option:
      strict: 1
      xhtml: 0

=head1 DESCRIPTION

This filter replaces text emoticons like ":-)", ";-P" etc. with
L<Text::Emoticon>.

=head1 CONFIG

=over 4

=item driver

Specify the driver's name of L<Text::Emoticon> you want to use. It
defaults to 'MSN'. 'Yahoo' and 'GoogleTalk' are also available.

=item option

Specify the options you want to pass to the L<Text::Emoticon>.

=back

=head1 AUTHOR

Naoya Ito E<lt>naoya@bloghackers.netE<gt>

=head1 SEE ALSO

L<Plagger>, L<Text::Emoticon>

=cut
