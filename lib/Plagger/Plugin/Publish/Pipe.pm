package Plagger::Plugin::Publish::Pipe;
use strict;
use base qw( Plagger::Plugin );

use Encode;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'publish.feed' => \&feed,
    );
}

sub feed {
    my($self, $context, $args) = @_;
    
    open my $out, "|" . $self->conf->{command} or $context->error("Can't open pipe: $!");
    $context->log(info => "Publishing to " . $self->conf->{command});
    for my $entry ($args->{feed}->entries) {
	print $out $self->convert($entry->title) . "\n";
	print $out $self->convert($entry->permalink) . "\n\n";
    }
    close $out;
}

sub convert {
    my ($self, $str) = @_;
    utf8::decode($str) unless utf8::is_utf8($str);
    return encode($self->conf->{encoding} || 'utf8', $str);
}

1;

__END__

=head1 NAME

Plagger::Plugin::Publish::Pipe - Publish to other program

=head1 SYNOPSIS

  - module: Publish::Pipe
    config:
      command: /usr/bin/mail youpy
      # command: /usr/bin/lpr
      # command: /usr/bin/fax
      # (for OSX user) command: /usr/bin/say
      encoding: iso-2022-jp

=head1 DESCRIPTION

This plugin publish feed updates to other program using a pipe.

=head1 AUTHOR

id:youpy

=head1 SEE ALSO

L<Plagger>

=cut
