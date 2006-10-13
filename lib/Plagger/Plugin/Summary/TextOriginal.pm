package Plagger::Plugin::Summary::TextOriginal;
use strict;
use base qw( Plagger::Plugin );

use Text::Original;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'summarizer.summarize' => \&summarize,
    );
}

sub summarize {
    my($self, $context, $args) = @_;
    first_sentence($args->{text}->plaintext);
}

1;
__END__

=head1 NAME

Plagger::Plugin::Summary::TextOriginal - uses Text::Original to get first sentence

=head1 SYNOPSIS

  - module: Summary::TextOriginal

=head1 DESCRIPTION

This plugin uses Text::Original CPAN module to generate summary off of
plaintext-ized body.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<Text::Original>

=cut
