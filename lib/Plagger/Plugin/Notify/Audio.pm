package Plagger::Plugin::Notify::Audio;
use strict;
use base qw( Plagger::Plugin );

use MP3::Info;

sub init {
    my $self = shift;
    $self->SUPER::init(@_);

    my $player = $self->conf->{player} || $^O;
    my $class  = 'Plagger::Plugin::Notify::Audio::' . $player;
    eval "require $class;";
    if ($@) {
        Plagger->context->error("Notify plugin doesn't run on your platform $player: $@");
    }
    bless $self, $class;
}

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'publish.entry' => \&update,
        'publish.finalize' => \&finalize,
    );
    $self->{enclosures} = [ ];
    $self->{count} = 0;
}

sub update {
    my($self, $context, $args) = @_;

    if ($self->conf->{play_enclosures}) {
        push @{$self->{enclosures}}, grep $_->local_path, $args->{entry}->enclosures;
    } else {
        $self->{count}++;
    }
}

sub finalize {
    my($self, $context, $args) = @_;

    if ($self->{count}) {
        $self->log(info => "Play " . $self->conf->{filename});
        return $self->play($self->conf->{filename});
    }

    for my $enclosure (@{$self->{enclosures}}) {
        # XXX this should be a separate plugin to handle MP4/WAV/ogg as well!
        my $info   = eval { MP3::Info->new($enclosure->local_path) };
        my $length = $info ? $info->secs : undef;
        $self->log(info => "Play " . $enclosure->local_path . ($length ? " for $length seconds" : ""));
        $self->play($enclosure->local_path, $length);
    }
}

sub play {
    my($self, $filename) = @_;
    $self->log(warn => "Subclass should override this");
}

1;
__END__

=head1 NAME

Plagger::Plugin::Notify::Audio - Notifies feed updates via audio file

=head1 SYNOPSIS

  # play single file when feeds are updated
  - module: Notify::Audio
    config:
      filename: /path/to/foo.wav

  # play enclosures downloaded with Filter::FetchEnclosure
  - module: Notify::Audio
    config:
      play_enclosures: 1

=head1 DESCRIPTION

This plugin plays audio file when you've got feed updates.

=head1 CONFIG

=over 4

=item filename

Audio filename to play. Required, if you don't set I<play_enclosures>.

=item play_enclosures

If set, it'll play local enclosure file which are downloaded via
Filter::FetchEnclosure, if any.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>

=cut
