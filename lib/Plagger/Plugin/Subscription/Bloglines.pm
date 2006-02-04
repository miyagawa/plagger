package Plagger::Plugin::Subscription::Bloglines;
use strict;
use base qw( Plagger::Plugin );

our $VERSION = '0.10';
use WebService::Bloglines;

sub register {
    my($self, $context) = @_;

    $self->init_bloglines();

    if ($self->conf->{no_sync_api}) {
        $context->register_hook(
            $self,
            'subscription.load'    => \&getsubs,
        );
    } else {
        $context->register_hook(
            $self,
            'subscription.load'    => \&notifier,
            'aggregator.aggregate' => \&sync,
        );
    }
}

sub getsubs {
    my($self, $context) = @_;
    my $subscription = $self->{bloglines}->listsubs();

    for my $folder ($subscription->folders) {
        $self->add_subscription($context, $subscription, $folder->{BloglinesSubId}, $folder->{title});
    }

    $self->add_subscription($context, $subscription, 0);
}

sub add_subscription {
    my($self, $context, $subscription, $subid, $title) = @_;

    my @feeds = $subscription->feeds_in_folder($subid);
    for my $source (@feeds) {
        my $feed = Plagger::Feed->new;
        $feed->title($source->{title});
        $feed->link($source->{htmlUrl});
        $feed->url($source->{xmlUrl} );
        $feed->tags([ $title ]) if $title;
        $context->subscription->add($feed);
    }
}

sub init_bloglines {
    my $self = shift;
    $self->{bloglines} = WebService::Bloglines->new(
        username => $self->conf->{username},
        password => $self->conf->{password},
    );
}

sub notifier {
    my($self, $context) = @_;

    my $count = $self->{bloglines}->notify();
    $context->log(debug => "You have $count unread item(s) on Bloglines.");
    $self->{bloglines_new} = $count;
}

sub sync {
    my($self, $context) = @_;

    return unless $self->{bloglines_new};

    my @updates = $self->{bloglines}->getitems(0, $self->conf->{mark_read});
    $context->log(debug => scalar(@updates) . " feed(s) updated.");

    for my $update (@updates) {
        my $source = $update->feed;

        my $feed = Plagger::Feed->new;
        $feed->title($source->{title});
        $feed->link($source->{link});
        $feed->image($source->{image});
        $feed->description($source->{description});
        $feed->language($source->{language});
        $feed->author($source->{webmaster});
        $feed->stash->{bloglines_id} = $source->{bloglines}->{siteid};

        for my $item ( $update->items ) {
            my $entry = Plagger::Entry->new;

            $entry->title($item->{title});
            $entry->author($item->{dc}->{creator});
            $entry->tags([ $item->{dc}->{subject} ])
                if $item->{dc}->{subject};
            $entry->date( Plagger::Date->parse('Mail', $item->{pubDate}) );
            $entry->link($item->{link});
            $entry->id($item->{guid});
            $entry->body($item->{description});

            $feed->add_entry($entry);
        }

        $context->update->add($feed);
    }
}

1;

