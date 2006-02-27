package Plagger::Plugin::Publish::MSAgent;
use base qw( Plagger::Plugin );

use strict;
use Win32::OLE;
use Win32::MSAgent 0.07;
use Encode;
use Locale::Country;
use Locale::Language;
use Time::HiRes 'sleep';

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'publish.feed' => \&feed,
    );
}

sub feed {
    my($self, $context, $args) = @_;

    my $character = $self->conf->{character} || 'Merlin';
    my $agent = Win32::MSAgent->new($character);

    my $char = $agent->Characters($character);
    $char->SoundEffectsOn(1);
    $char->Show();

    my @pos = split /,\s*/, ($self->conf->{position} || "300,300");
    $char->MoveTo(@pos);
    sleep(5);

    if (my $animation = $self->conf->{animation}) {
        $char->Play($animation);
    }

    my($lang, $encoding) = $self->detect_locale( ($args->{feed}->entries)[0] );

    my($t1, $t2) = split /-/, $lang;
    my $key = code2language($t1);
       $key.= " (".code2country($t2).")" if code2country($t2);

    # xxx hack to load VoiceText
    $agent->Language2LanguageID("English (United States)"); 
    my $voice = $agent->{_vt};

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

    $self->speak( $char, encode($encoding, $args->{feed}->title_text) );

    for my $entry ($args->{feed}->entries) {
        $self->speak( $char, encode($encoding, $entry->title_text) );
        my $text = $entry->body_text;
        while ($text =~ s/^(.{64})//) {
            $self->speak( $char, encode($encoding, $1) );
        }
        $self->speak( $char, encode($encoding, $text) ) if $text;
    }
}

sub detect_locale {
    my($self, $entry) = @_;

    my $stuff = $entry->title_text . $entry->body_text;

    # HACK this should be handled in $entry->locale
    my $lang     = $stuff =~ /\p{Hiragana}|\p{Katakana}|\p{Han}/ ? 'ja' : 'en-us';
    my $encoding = $lang eq 'ja' ? 'cp932' : 'latin-1';

    return ($lang, $encoding);
}

sub speak {
    my($self, $character, $message) = @_;
    my $request = $character->Speak($message);

    my $i = 0;
    while (($request->Status == 2) || ($request->Status == 4)) {
        $character->Stop($request) if $i >10; sleep(1);  $i++;
    }
}

1;

__END__

=head1 NAME

Plagger::Plugin::Publish::MSAgent - Let your Agent speak feed updates

=head1 SYNOPSIS

  - module: Publish::MSAgent
    config:
      character: Merlin
      voice: male
      position: 300,300
      animation: Announce

=head1 DESCRIPTION

This plugin uses Microsoft Agent API to let your agent speack feed updates.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<Win32::MSAgent>

=cut
