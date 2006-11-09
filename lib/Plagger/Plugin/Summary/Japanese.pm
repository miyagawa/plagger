package Plagger::Plugin::Summary::Japanese;
use strict;
use base qw( Plagger::Plugin );

use Lingua::JA::Summarize::Extract;

sub register {
    my($self, $context) = @_;
    $context->autoload_plugin({ module => 'Filter::GuessLanguage' });
    $self->{extracter} = Lingua::JA::Summarize::Extract->new($self->conf);
    $context->register_hook(
        $self,
        'summarizer.summarize' => \&summarize,
    );
}

sub summarize {
    my($self, $context, $args) = @_;

    my $lang = $args->{entry}->language || $args->{feed}->language;
    return unless $lang && $lang eq 'ja';

    my $summary = $self->{extracter}->extract($args->{entry}->body->plaintext);
    $summary->length(128) unless $self->conf->{length};
    return $summary->as_string;
}

1;
__END__

=head1 NAME

Plagger::Plugin::Summary::Japanese -

=head1 SYNOPSIS

  - module: Summary::Japanese

=head1 DESCRIPTION

XXX Write the description for Summary::Japanese

=head1 CONFIG

XXX Document configuration variables if any.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<Lingua::JA::Summarize::Extract>

=cut
