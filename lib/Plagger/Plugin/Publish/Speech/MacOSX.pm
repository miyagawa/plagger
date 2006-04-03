package Plagger::Plugin::Publish::Speech::MacOSX;
use base qw( Plagger::Plugin::Publish::Speech );

use strict;
use DirHandle;
use Mac::Files;
use Mac::Speech;

sub feed {
    my ($self, $context, $args) = @_;

#    unless( $self->is_ascii( $args->{feed}->title_text ) ){
#        Plagger->context->log(info => "Skip 2byte-included feed: " . $args->{feed}->title_text);
#        return;
#    }

    my $voice = $self->conf->{voice} || 'Vicki';
    if( $self->voice_validate( $voice ) ){
        Plagger->context->log(debug => "$voice is ready to speak.");
    }
    else{
        Plagger->context->log(info => "Voice '$voice' not found, will be replaced to 'Vicki'.");
        $voice = 'Vicki';
    }

    my $speed;
    if( $self->conf->{speed} =~ /^\d+(\.\d+)*$/o ){
        $speed = $self->conf->{speed};
        $speed = 4.0
            if $speed > 4.0;
        Plagger->context->log(debug => "Speed will be multiplied by $speed.")
            if $speed != 1.0;
    }

    my $pitch;
    if( $self->conf->{pitch} =~ /^\d+(\.\d+)*$/o ){
        $pitch = $self->conf->{pitch};
        $pitch = 2.0
            if $pitch > 2.0;
        Plagger->context->log(debug => "Pitch will be multiplied by $pitch.")
            if $pitch != 1.0;
    }

    $self->speak( $voice, $speed, $pitch, $args->{feed}->title_text );

    for my $entry ($args->{feed}->entries) {
        my $stuff = $entry->title_text . ' ' . $entry->body_text;

#        unless( $self->is_ascii( $stuff ) ){
#            Plagger->context->log(info => "Can't speak 2byte-included entry, sorry.");
#            next;
#        }

        $self->speak( $voice, $speed, $pitch, $stuff );
    }
}

sub voice_validate {
    my ($self, $voice) = @_;

    if( my $d = DirHandle->new( FindFolder(kOnSystemDisk, kVoicesFolderType) ) ){
        while( defined ($_ = $d->read) ){
            return 1
                if /^$voice\.SpeechVoice$/i;
        }
    }
}

sub is_ascii {
    my ($self, $str) = @_;

    return $str =~ /[^\x00-\x7f]/o ? 0 : 1;
}

sub speak {
    my ($self, $voice, $speed, $pitch, $message) = @_;

    if( my $v = $Mac::Speech::Voice{ $voice } ){
        my $channel = Mac::Speech::NewSpeechChannel( $v );

        SetSpeechRate( $channel, GetSpeechRate( $channel ) * $speed )
            if $speed;

        SetSpeechPitch( $channel, GetSpeechPitch( $channel ) * $pitch )
            if $pitch;

        SpeakText( $channel => $message );
        sleep 1
            while SpeechBusy;

        DisposeSpeechChannel( $channel );
    }
    else{
        Plagger->context->log(error => "Voice sound file for '$voice' not found on your machine.");
        return;
    }
}

sub finalize { }

1;

__END__

=head1 NAME

Plagger::Plugin::Publish::Speech::MacOSX - speak your subscription on MacOSX

=head1 SYNOPSIS

  - module: Publish::Speech
    config:
      voice: Vicki
      speed: 0.96
      pitch: 1.05

=head1 DESCRIPTION

Your Mac now speaks your subscriptions.

=head1 Config

=head2 voice

Following voices are available on MacOSX 10.4.

 Agnes
 Albert
 BadNews
 Bahh
 Bells
 Boing
 Bruce
 Bubbles
 Cellos
 Deranged
 Fred
 GoodNews
 Hysterical
 Junior
 Kathy
 Organ
 Princess
 Ralph
 Trinoids
 Vicki
 Victoria
 Whisper
 Zarvox

=head2 speed

You can control the speed with setting multiplication factor (0.0 to 4.0).

=head2 pitch

You can control the sound pitch with setting multiplication factor (0.0 to 2.0).

=head1 CAVEATS

Only ascii feeds are available for speech.

=head1 AUTHOR

Ryo Okamoto <ryo@aquahill.net>

Based on the plugin Plagger::Plugin::Speech::Win32 by Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<Mac::Speech>

http://www.apple.com/education/accessibility/technology/text_to_speech.html

=cut

