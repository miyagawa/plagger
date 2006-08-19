package Plagger::Plugin::Notify::Audio;
use strict;
use base qw( Plagger::Plugin::Notify::Eject );

sub init {
    my $self = shift;
    $self->SUPER::init(@_);

    my $player = $self->conf->{player} || $^O;
    my $class  = 'Plagger::Plugin::Notify::Audio::' . $player;
    eval "require $class;";
    if ($@) {
        Plagger->context->error("Notify plugin doesn't run on your platform $player");
    }
    bless $self, $class;
}

sub eject {
    my($self, $context, $args) = @_;
    $self->play($context, $self->conf->{filename});
}

sub play {
    my($self, $context, $args) = @_;
    $self->log(warn => "Subclass should override this");
}

1;
__END__

=head1 NAME

Plagger::Plugin::Notify::Audio - Notifies feed updates via audio file

=head1 SYNOPSIS

  - module: Notify::Audio
    config:
      filename: /path/to/foo.wav

=head1 DESCRIPTION

This plugin plays audio file when you've got feed updates.

=head1 CONFIG

=over 4

=item filename

Audio filename to play. Required.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>

=cut
