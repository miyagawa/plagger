package Plagger::Plugin::CustomFeed::Mixi;
use strict;
use base qw( Plagger::Plugin );

use DateTime::Format::Strptime;
use Encode;
use WWW::Mixi;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'subscription.load' => \&load,
        'aggregator.aggregate.mixi' => \&aggregate,
    );
}

sub load {
    my($self, $context) = @_;
    $self->{mixi} = WWW::Mixi->new($self->conf->{email}, $self->conf->{password});

    my $feed = Plagger::Feed->new;
       $feed->type('mixi');
    $context->subscription->add($feed);
}

sub aggregate {
    my($self, $context, $sub) = @_;

    my $response = $self->{mixi}->login;
    unless ($response->is_success) {
        $context->log(error => "Login failed.");
    }

    $context->log(info => 'Login to mixi succeed.');

    my $feed = Plagger::Feed->new;
    $feed->type('mixi');
    $feed->title('マイミクシィ最新日記');
    $feed->link('http://mixi.jp/new_friend_diary.pl');

    my $format = DateTime::Format::Strptime->new(pattern => '%Y/%m/%d %H:%M');

    my @msgs = $self->{mixi}->get_new_friend_diary;
    $context->log(info => scalar(@msgs). " messages from new_friend_diary.pl");

    for my $msg (@msgs) {
        next unless $msg->{image}; # external blog

        my $entry = Plagger::Entry->new;
        $entry->title( decode('euc-jp', $msg->{subject}) );
        $entry->link($msg->{link});
        $entry->author( decode('euc-jp', $msg->{name}) );
        $entry->date( Plagger::Date->parse($format, $msg->{time}) );

        $feed->add_entry($entry);
    }

    $context->update->add($feed);
}

1;

