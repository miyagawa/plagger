package Plagger::Plugin::Notify::Command;
use strict;
use base qw( Plagger::Plugin );

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'publish.feed' => \&update,
        'publish.finalize' => \&finalize,
        'plugin.init'  => \&plugin_init,
    );
}

sub plugin_init {
    my($self, $context, $args) = @_;

    unless (exists $self->conf->{command}) {
        $context->error("'command' config is missing");
    }
}

sub update {
    my($self, $context, $args) = @_;
    $self->{count}++ if $args->{feed}->count;
}

sub finalize {
    my($self, $context, $args) = @_;
    $self->do_command if $self->{count};
}

sub do_command {
    my $self = shift;
    my $command = $self->conf->{command};
    system($command);
}

1;
__END__

=head1 NAME

Plagger::Plugin::Notify::Command - Execute arbitrary command or script when you have an updated feed

=head1 SYNOPSIS

  - module: Notify::Command
    config:
      command: /path/to/script

=head1 DESCRIPTION

This plugin executes arbitrary command using Perl system() function,
when you have an updated feed. Specified command is executed only once
when your entire subscription has an updated feed.

=head1 CONFIG

=over 4

=item command

  command: echo "Hello World"

Specify the path of command (and arguments to the command) to
execute. The command is executed using Perl's I<system> function, so
it would use shell.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>

=cut
