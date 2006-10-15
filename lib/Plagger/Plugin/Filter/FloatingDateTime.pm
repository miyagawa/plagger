package Plagger::Plugin::Filter::FloatingDateTime;
use strict;
use base qw( Plagger::Plugin );

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'update.entry.fixup' => \&update,
    );
    $self->{tz} = $self->conf->{timezone} || $context->conf->{timezone} || 'local';
}

sub update {
    my($self, $context, $args) = @_;
    $args->{entry}->date and $args->{entry}->date->time_zone->is_floating and
	$args->{entry}->date->set_time_zone($self->{tz});
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::FloatingDateTime - fix floating timezone

=head1 SYNOPSIS

    - module: Filter::FloatingDateTime

=head1 DESCRIPTION

This plugin fixes a floating timezone.

=head1 AUTHOR

Masahiro Nagano

=head1 SEE ALSO

L<Plagger>, L<DateTime>

=cut


