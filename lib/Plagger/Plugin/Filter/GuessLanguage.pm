package Plagger::Plugin::Filter::GuessLanguage;
use strict;
use base qw( Plagger::Plugin );

use Text::Language::Guess;
use Locale::Language;
use Lingua::ZH::HanDetect;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'plugin.init'        => \&init_guesser,
        'update.entry.fixup' => \&guess,
    );
}

sub rule_hook { 'update.entry.fixup' }

my $re_western_lang_code = qr/^(?:en|fr|es|pt|it|de|nl|sv|no|da)$/;

sub init_guesser {
    my ($self, $context, $args) = @_;

    my @western_languages; # ie. Text::Language::Guess-able languages
    my %accepts;

    foreach my $lang (@{ $self->conf->{languages} || [] }) {

        # see if $lang is human friendly lang name
        if (my $code = language2code($lang)) {
            push @western_languages, $code if $code =~ $re_western_lang_code;
            $accepts{$code} = 1;
        }

        # see if $lang is existing lang code
        elsif (my $name = code2language($lang)) {
            push @western_languages, $lang if $lang =~ $re_western_lang_code;
            $accepts{$lang} = 1;
        }

        # $lang is something wrong or unsupported
        else {
            $context->log(warn => "no such language: $lang");
        }
    }

    $self->{guess_language}->{accepts} = \%accepts;
    $self->{guess_language}->{western} = Text::Language::Guess->new( 
        @western_languages
            ? ( languages => \@western_languages )
            : ()
    );
}

sub guess {
    my ($self, $context, $args) = @_;

    my $target = $self->conf->{target} || 'feed';

    my $guessed;
    if (!$guessed && $target =~ /both|entry/) {
        $guessed = $self->guess_entry($context, $args);
    }
    if (!$guessed && $target =~ /both|feed/) {
        $guessed = $self->guess_feed($context, $args);
    }
}

sub guess_language {
    my ($self, $text) = @_;

    return unless defined $text && length $text;

    my $code;

    # xxx: just a quick hack. there may be a better way.

    my %accepts = %{ $self->{guess_language}->{accepts} };

    if (!%accepts || $accepts{ja}) {
        return 'ja' if $text =~ /\p{Hiragana}|\p{Katakana}/s;
    }
    if (!%accepts || $accepts{ko}) {
        return 'ko' if $text =~ /\p{Hangul}/s;
    }
    if (!%accepts || $accepts{zh}) {
        my ($encoding, $variant) = Lingua::ZH::HanDetect::han_detect($text);
        return 'zh' if $encoding && $variant; # maybe chinese (but maybe j/k)
    }

    $code = $self->{guess_language}->{western}->language_guess_string($text);

    # skip if no western lang is allowed
    return $code if !%accepts || $accepts{$code};

    return;  # doomed!
}

sub guess_feed {
    my ($self, $context, $args) = @_;

    return $args->{feed}->language if $args->{feed}->language;

    $context->log(debug => "start guessing language");

    my $body = join "\n", map $_->body_text, $args->{feed}->entries;

    my $code = $self->guess_language($body);

    if ($code) {
        $context->log(debug => "guessed: $code");
        $args->{feed}->language($code);
        return $code;
    }
    else {
        $context->log(debug => "can't identify the feed's language");
        return;
    }
}

sub guess_entry {
    my ($self, $context, $args) = @_;

    return $args->{entry}->language if $args->{entry}->language;

    $context->log(debug => "start guessing entry's language");

    my $code = $self->guess_language($args->{entry}->body_text);

    if ($code) {
        $context->log(debug => "guessed: $code");
        $args->{entry}->language($code);
        return $code;
    }
    else {
        $context->log(debug => "can't identify the entry's language");
        return;
    }
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::GuessLanguage - guess language of feeds/entries

=head1 SYNOPSIS

  - module: Filter::GuessLanguage
    config:
      languages:
        - en
        - de
        - Japanese
      target: both

=head1 DESCRIPTION

=head1 CONFIG

=over 4

=item languages (optional)

Which languages you think the feeds/entries are written in.
English language names and ISO two letter codes are acceptable.
Unless you DO want to limit, specify nothing.

=item target

'entry' or 'feed' (default) or 'both'.

=back

=head1 AUTHOR

Kenichi Ishigaki

=head1 SEE ALSO

L<Plagger>, L<Text::Language::Guess>

=cut
