package Plagger::Plugin::Filter::ForceTimeZone;
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
    $args->{entry}->date and
	$args->{entry}->date->set_time_zone($self->{tz});
}

1;
__END__

=head1 NAME

Plagger::Plugin::Filter::ForceTimeZone - Force set Timezone regardless of it's UTC or floating

=head1 SYNOPSIS

  - module: Filter::ForceTimeZone

=head1 DESCRIPTION

This plugin force fixes timezone of entries datetime to that of
Plagger global timezone. While Filter::FloatingDateTime only fixed
timezone when datetime is floating, this plugin changes all datetime
TZ regardless of it's UTC or floating.

If global timezone is not set, this module tries to use system local
timezone.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<Plagger::Plugin::Filter::FloatingDateTime>

=cut
