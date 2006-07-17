package Plagger::Plugin::Notify::Balloon;
use strict;
use base qw( Plagger::Plugin );

our $VERSION = '0.01';

use Encode ();

sub register {
    my($self, $context) = @_;

    if ($^O eq 'MSWin32') {
        $context->register_hook(
            $self,
            'publish.entry' => \&notify,
            'plugin.init'   => \&initialize,
        );
    } else {
        $context->log(error => "This plugin only works on Win32 systems");
    }
}

sub initialize {
    my($self, $context) = @_;

    return if $self->conf->{encoding};

    my $cp = eval {
        require Win32::Console;
        Win32::Console::OutputCP();
    };
    $cp ||= 932; # cp932 by default ... for Japanese environment
    $self->conf->{encoding} = "cp$cp";
}

sub notify {
    my($self, $context, $args) = @_;

    my $title   = $self->scrub($args->{entry}->title);
    my $message = $self->scrub($args->{entry}->body_text);

    my @command = ('BalloonNotify', '/o', 5, '/t', $title, '/c', $message);
    !system(@command) or $context->log(error => $?);
}

sub scrub {
    my($self, $string) = @_;
    $string =~ s/\s+/ /;
    Encode::encode($self->conf->{encoding}, $string);
}

1;

__END__

=head1 NAME

Plaggr::Plugin::Notify::Balloon - Notify feed updates using Win32 BalloonNotify

=head1 SYNOPSIS

  - module: Notify::Balloon

=head1 DESCRIPTION

This plugin uses Windows Balloon notification system to notify feed
updates to users.

=head1 AUTHOR

Tatsuhiko Miyagawa

Original code was taken from http://yaplog.jp/sumikko/archive/34

=head1 SEE ALSO

L<Plagger>

=cut
