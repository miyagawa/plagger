package Plagger::Plugin::Filter::Babelfish;
use strict;
use base qw( Plagger::Plugin );

use Plagger::UserAgent;
use WWW::Babelfish;
use Digest::MD5 qw(md5_hex);
use Encode qw(encode_utf8);

use Locale::Language;

sub register {
    my($self, $context) = @_;

    $context->autoload_plugin({ module => 'Filter::GuessLanguage' });
    $context->register_hook(
        $self,
        'plugin.init'        => \&connect_to_babelfish,
        'update.entry.fixup' => \&update,
    );
}

sub rule_hook { 'update.entry.fixup' }

sub connect_to_babelfish {
    my($self, $context, $args) = @_;

    my $service = $self->conf->{service} || 'Babelfish';

    $context->log(debug => "hello, $service");

    my $ua = Plagger::UserAgent->new;
    $self->{babelfish}->{translator} = new WWW::Babelfish(
        service => $service,
        agent => $ua->agent
    );
    unless (defined $self->{babelfish}->{translator}) {
        $context->log(error => "$service is not available");
        return;
    }
}

sub update {
    my($self, $context, $args) = @_;

    my $translator = $self->{babelfish}->{translator} or return;
    my $language   = $self->conf->{source} || code2language(
        $args->{entry}->{language} || $args->{feed}->language
    ) or do {
        $context->log(warn => "can't identify language");
        return;
    };

    my $title    = $args->{entry}->title;
    my $title_tr = $self->translate($translator, $title, $language);
    unless (defined $title_tr) {
        $context->log(error => "Translation failed: " . $translator->error);
        return;
    }
    $title_tr = $title . "\n\n" . $title_tr if $self->conf->{prepend_original};

    $args->{entry}->title($title_tr);

    sleep 1;

    my $body    = $args->{entry}->body;
    my $body_tr = $self->translate($translator, $body, $language);
    unless (defined $body_tr) {
        $context->log(error => "Translation failed: " . $translator->error);
        return;
    }
    if ($self->conf->{prepend_original}) {
        $body_tr = $body . "\n\n" . $body_tr;
        $context->log(debug => "prepended original body");
    }

    $args->{entry}->body($body_tr);
}

sub translate {
    my ($self, $translator, $text, $language) = @_;

    my $destination = $self->conf->{destination} or do {
      Plagger->context->log(error => "set destination language");
      return;
    };

    unless ($translator->languagepairs->{$language}->{$destination}) {
      Plagger->context->log(
          error => "unsupported combination: $language to $destination"
      );
      return;
    }

    my $key = md5_hex(encode_utf8($text));

    return $self->cache->get_callback(
        "babelfish-$key-$destination",
        sub {
            $translator->translate(
                source      => $language,
                destination => $destination,
                text => $text,
                delimiter => "\n\n",
            );
        },
        '3 days'
    );
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::Babelfish - translate via WWW::Babelfish

=head1 SYNOPSIS

  - module: Filter::Babelfish
    config:
      source: English
      destination: Japanese
      service: Google
      prepend_original: 1

=head1 DESCRIPTION

This plugin translates each entry body via Babelfish.
See L<WWW::Babelfish> for details.

=head1 CONFIG

=over 4

=item service

Which translator to use ('Babelfish' or 'Google').
Defaults to 'Babelfish'.

=item source (optional)

Which language the feeds/entries are. Will be guessed if you don't specify.

=item destination

Which language the feeds/entries should be translated to.

=item prepend_original

When set to 1, prepends original entry body. Defaults to 0.

=back

=head1 AUTHOR

Kenichi Ishigaki

=head1 SEE ALSO

L<Plagger>, L<WWW::Babelfish>

=cut
