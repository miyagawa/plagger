package Plagger::Plugin::Notify::Eject;
use strict;
use base qw( Plagger::Plugin );

sub init {
    my $self = shift;
    $self->SUPER::init(@_);

    my $class = 'Plagger::Plugin::Notify::Eject::' . lc($^O);
    eval "require $class;";
    if ($@) {
        Plagger->context->error("Eject plugin doesn't run on your platform $^O");
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
    $self->eject if $self->{count};
}

sub eject { $_[1]->log(warn => 'Subclass should override this') }

1;

__END__

=head1 NAME

Plagger::Plugin::Notify::Eject - Notify feed updates to CD Drive

=head1 SYNOPSIS

  - module: Notify::Eject

=head1 DESCRIPTION


=head1 AUTHOR

Kazuhiro Osawa

=head1 SEE ALSO

L<Plagger>, L<Plagger::Plugin::Notify::Eject::linux>, L<Plagger::Plugin::Notify::Eject::freebsd>,
L<Plagger::Plugin::Notify::Eject::mswin32>, L<Plagger::Plugin::Notify::Eject::darwin>

=cut
