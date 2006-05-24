package Plagger::Plugin::Notify::Campfire;

use strict;
use base qw( Plagger::Plugin );
use Time::HiRes;

our $VERSION = 0.01;

sub plugin_id {
    my $self = shift;
    $self->class_id . '-' . $self->conf->{email};
}

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
use Plagger::Mechanize;
use HTTP::Request::Common;
use Encode;

sub new {
    my $class  = shift;
    my $plugin = shift;

    my $mech = Plagger::Mechanize->new(cookie_jar => $plugin->cookie_jar);
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
        $self->{mecha}->submit_form(
            fields => {
                name => $self->{nickname},
                remember => 1,
            },
        );
    }
    else {
        $self->{mecha}->submit_form(
            fields => {
                email_address => $self->{email},
                password      => $self->{password},
                remember      => 1,
            },
        );
    }
    $self->{mecha}->submit;
    return 0 unless $self->{mecha}->success;
    return 0 if $self->{mecha}->content =~ /Oops/;

    unless ( $self->{room_url} ) {
        $self->{room_url} = $self->{guest_url};
        my ( $room_no, ) = $self->{mecha}->content =~ /participant_list-(\d+)/;
        $self->{room_url} =~ s!/\w+$!/room/$room_no!;
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

=head1 NAME

Plagger::Plugin::Notify::Campfire - Notification bot for Campfire

=head1 SYNOPSIS

To use bot as a guest (recommended),

  - module: Notify::Campfire
    config:
      guest_url: http://exmaple.campfirenow.com/room/NNNN
      nickname: nickname
      speak_interval: 3

Or, to use bot using existent login credentials,

  - module: Notify::Campfire
    config:
      room_url: http://exmaple.campfirenow.com/NNNN
      email: example@example.com
      password: xxxxxx
      speak_interval: 2

=head1 DESCRIPTION

This plugin notifies feed updates to 37 Signals' Campfire
L<http://www.campfirenow.com/> chat room.

Note that you don't have to supply emali and password if you set
global cookie_jar in your configuration file and the cookie_jar
contains a valid login session there, such as:

  global:
    user_agent:
      cookies: /path/to/cookies.txt

See L<Plagger::Cookies> for details.

=head1 AUTHOR

Takeshi Nagayama

=head1 SEE ALSO

L<Plagger>, L<http://www.campfirenow.com/>, L<WWW::Mechanize>

=cut
