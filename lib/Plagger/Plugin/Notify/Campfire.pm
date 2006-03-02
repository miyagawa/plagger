
package Plagger::Plugin::Notify::Campfire;

use strict;
use base qw( Plagger::Plugin );
use Time::HiRes;

our $VERSION = 0.01;

sub register {
    my ( $self, $context ) = @_;
    $context->register_hook(
        $self,
        'publish.init'  => \&initialize,
        'publish.entry' => \&publish_entry,
    );
}

sub initialize {
    my ( $self, $context ) = @_;
    $self->{campfire} =
      Plagger::Plugin::Notify::Campfire::Mechanize->new($self);
    unless ( $self->{campfire}->login ) {
        $context->log( error => "Login to Campfire failed." );
        return;
    }
    $context->log( info => 'Login to Campfire succeeded.' );
}

sub publish_entry {
    my ( $self, $context, $args ) = @_;
    $self->{campfire}->speak( $args->{entry}->title );
    $self->{campfire}->speak( $args->{entry}->link );
    $context->log( info => 'Speak: ' . $args->{entry}->title );
    Time::HiRes::sleep( $self->conf->{speak_interval} || 2 );
}

package Plagger::Plugin::Notify::Campfire::Mechanize;

use strict;
use WWW::Mechanize;
use HTTP::Request::Common;
use Encode;

sub new {
    my $class  = shift;
    my $plugin = shift;

    my $mech = WWW::Mechanize->new(cookie_jar => $plugin->cache->cookie_jar);
    $mech->agent_alias("Windows IE 6");

    bless {
        mecha      => $mech,
        nickname   => $plugin->conf->{nickname},
        email      => $plugin->conf->{email},
        password   => $plugin->conf->{password},
        room_url   => $plugin->conf->{room_url},
        guest_url  => $plugin->conf->{guest_url},
    }, $class;
}

sub login {
    my $self = shift;

    my $start_url = $self->{guest_url} || $self->{room_url};
    my $res = $self->{mecha}->get($start_url);
    return 0 unless $self->{mecha}->success;

    # still login
    return 1 if ( $self->{mecha}->content =~ /chat-wrapper/);
    
    if ( $self->{guest_url} ) {
        $self->{mecha}
          ->submit_form( fields => { name => $self->{nickname}, }, );
    }
    else {
        $self->{mecha}->submit_form(
            fields => {
                email_address => $self->{email},
                password      => $self->{password},
            },
        );
    }
    $self->{mecha}->submit;
    return 0 unless $self->{mecha}->success;
    return 0 if $self->{mecha}->content =~ /Oops/;

    unless ( $self->{room_url} ) {
        $self->{room_url} = $self->{guest_url};
        my ( $room_no, ) = $self->{mecha}->content =~ /participant_list-(\d+)/;
        $self->{room_url} =~ s/\/\w+$/\/room\/$room_no/;
    }

}

sub speak {
    my ( $self, $message ) = @_;
    $self->{mecha}->request(
        POST $self->{room_url} . "/speak",
        [ message => encode( 'utf-8', $message ) ]
    );
    return 0 unless $self->{mecha}->success;
}

1;

__END__

- module: Notify::Campfire
config:
  guest_url: http://exmaple.campfirenow.com/room/xxxxx
  nickname: nickname
  speak_interval: 3

OR

- module: Notify::Campfire
config:
  room_url: http://exmaple.campfirenow.com/xxxxxx
  email: example@example.com
  password: xxxxxx
  speak_interval: 2

