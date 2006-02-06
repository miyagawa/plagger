package Plagger::Plugin::CustomFeed::Mixi;
use strict;
use base qw( Plagger::Plugin );

use DateTime::Format::Strptime;
use Encode;
use WWW::Mixi;
use Time::HiRes;

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
    my($self, $context, $args) = @_;

    my $response = $self->{mixi}->login;
    unless ($response->is_success) {
        $context->log(error => "Login failed.");
        return;
    }

    $context->log(info => 'Login to mixi succeed.');

    my $feed = Plagger::Feed->new;
    $feed->type('mixi');
    $feed->title('マイミクシィ最新日記');
    $feed->link('http://mixi.jp/new_friend_diary.pl');

    my $format = DateTime::Format::Strptime->new(pattern => '%Y/%m/%d %H:%M');

    my @msgs = $self->{mixi}->get_new_friend_diary;
    my $items = $self->conf->{fetch_items} || 20;

    my $i = 0;
    my $blocked = 0;
    for my $msg (@msgs) {
        next unless $msg->{image}; # external blog
        last if $i++ >= $items;

        my $entry = Plagger::Entry->new;
        $entry->title( decode('euc-jp', $msg->{subject}) );
        $entry->link($msg->{link});
        $entry->author( decode('euc-jp', $msg->{name}) );
        $entry->date( Plagger::Date->parse($format, $msg->{time}) );

        if ($self->conf->{fetch_body} && !$blocked) {
            $context->log(info => "Fetch body from $msg->{link}");
            Time::HiRes::sleep( $self->conf->{fetch_body_interval} || 1.5 );
            my($item) = $self->{mixi}->get_view_diary($msg->{link});
            if ($item) {
                my $body = decode('euc-jp', $item->{description});
                   $body =~ s!\n!<br />!g;
                for my $image (@{ $item->{images} }) {
                    # xxx this should be $entry->enclosures
                    $body .= qq(<div><a href="$image->{link}"><img src="$image->{thumb_link}" style="border:0" /></a></div>);
                }
                $entry->body($body);
            } else {
                $context->log(warn => "Fetch body failed. You might be blocked?");
                $blocked++;
            }
        }

        $feed->add_entry($entry);
    }

    $context->update->add($feed);
}

1;

