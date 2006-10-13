package Plagger::Plugin::Summary::English;
use strict;
use base qw( Plagger::Plugin );

use Lingua::EN::Summarize ();

sub register {
    my($self, $context) = @_;
    $context->autoload_plugin({ module => 'Filter::GuessLanguage' });
    $context->register_hook(
        $self,
        'summarizer.summarize' => \&summarize,
    );
}

sub summarize {
    my($self, $context, $args) = @_;

    my $lang = $args->{entry}->language || $args->{feed}->language;
    return unless $lang && $lang eq 'en';

    Lingua::EN::Summarize::summarize( $args->{text}->plaintext );
}

1;
__END__

=head1 NAME

Plagger::Plugin::Summary::English - uses Lingua::EN::Summarizer to generate summary

=head1 SYNOPSIS

  - module: Summary::English

=head1 DESCRIPTION

This plugin uses Lingua::EN::Summary to generate summary, if entry language is in English.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<Filter::GuessLanguage>, L<Lignau::EN::Summarize>

=cut
