package Plagger::Plugin::Notify::Beep;
use strict;
use base qw( Plagger::Plugin );

use Audio::Beep;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'publish.feed' => \&update,
        'publish.finalize' => \&finalize,
    );
    $self->{count} = 0;
}

sub update {
    my($self, $context, $args) = @_;
    $self->{count}++ if $args->{feed}->count;
}

sub finalize {
    my($self, $context, $args) = @_;
    if ($self->{count}) {
        if ($self->conf->{music}) {
            Audio::Beep->new->play($self->conf->{music});
        } else {
            Audio::Beep::beep;
        }
    }
}

1;

__END__

=head1 NAME

Plagger::Plugin::Notify::Beep - Beep your computer when feed arrives

=head1 SYNOPSIS

  - module: Notify::Beep
    config:
      music: "g' f bes' c8 f d4 c8 f d4 bes c g f2"

=head1 DESCRIPTION

Beep your computer when feed arrives.

=head1 CONFIG

=over 4

=item music

When it is set, beep tries to play a melody specified as Lilypond
notation. Defaults to nothing and in that case, it just beeps.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<Audio::Beep>

=cut
