package Plagger::Plugin::Publish::Speech::Win32;
use base qw( Plagger::Plugin::Publish::Speech );

use strict;
use Encode;
use Locale::Country;
use Locale::Language;
use Time::HiRes 'sleep';
use Win32::OLE;
use Win32::SAPI4;

sub feed {
    my($self, $context, $args) = @_;

    my $voice = Win32::SAPI4::VoiceText->new;
    $self->speak($voice, encode("utf-8", $args->{feed}->title_text) );

    for my $entry ($args->{feed}->entries) {
        my $stuff = $entry->title_text . $entry->body_text;

        # HACK this should be handled in $entry->locale
        my $lang     = $stuff =~ /\p{Hiragana}|\p{Katakana}|\p{Han}/ ? 'ja' : 'en-us';
        my $encoding = $lang eq 'ja' ? 'cp932' : 'latin-1';

	$self->speak($voice, $lang, encode($encoding, $stuff) );
    }
}

sub speak {
    my($self, $voice, $lang, $message) = @_;

    my($t1, $t2) = split /-/, $lang;
    my $key = code2language($t1);
       $key.= " (".code2country($t2).")" if code2country($t2);

    my $code = $voice->Language2LanguageID($key);
    my $gender = $self->conf->{voice} || 'male';
    my @try_gender  = $gender =~ /^male$/i ? (1, 2) : (2, 1);

 TRY: for my $gender (@try_gender) {
        for my $i (1 .. $voice->CountEngines) {
            if ( $voice->LanguageID($i) == $code && $voice->Gender($i) == $gender ) {
                Plagger->context->log(debug => "Found voice $i for Lang $lang and Gender $gender");
                $voice->Select($i);
                last TRY;
            }
        }
    }

    $voice->Speak($message);
    sleep 1 while $voice->IsSpeaking;
}

1;
