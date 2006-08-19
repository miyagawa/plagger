package Plagger::Plugin::Notify::Audio;
use strict;
use base qw( Plagger::Plugin );

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
    $self->play($self->conf->{filename}) if $self->{count};
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

  - module: Notify::Audio
    config:
      filename: /path/to/foo.wav

=head1 DESCRIPTION

This plugin plays audio file when you've got feed updates.

=head1 CONFIG

=over 4

=item filename

Audio filename to play. Required.

=back

=head1 TODO

=over 4

=item *

Configurable audio name per feed.

=item *

Play enclosures?

=back

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>

=cut
