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
            'subscription.load' => \&getsubs,
        );
    } else {
        $context->register_hook(
            $self,
            'subscription.load' => \&notifier,
            'aggregator.aggregate.bloglines' => \&sync,
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
    $context->log(info => "You have $count unread item(s) on Bloglines.");
    if ($count) {
        my $feed = Plagger::Feed->new;
        $feed->type('bloglines');
        $context->subscription->add($feed);
    }
}

sub sync {
    my($self, $context, $args) = @_;

    my $mark_read = $self->conf->{mark_read};
       $mark_read = 1 unless defined $mark_read;

    my @updates = $self->{bloglines}->getitems(0, $mark_read);
    $context->log(dnfo => scalar(@updates) . " feed(s) updated.");

    for my $update (@updates) {
        my $source = $update->feed;

        my $feed = Plagger::Feed->new;
        $feed->type('bloglines');
        $feed->title($source->{title});
        $feed->link($source->{link});
        $feed->image($source->{image});
        $feed->description($source->{description});
        $feed->language($source->{language});
        $feed->author($source->{webmaster});
        $feed->meta->{bloglines_id} = $source->{bloglines}->{siteid};
        $feed->source_xml($update->{_xml});

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

__END__

=head1 NAME

Plagger::Plugin::Subscription::Bloglines - Bloglines Subscription

=head1 SYNOPSIS

  - module: Subscription::Bloglines
    config:
      username: your-email@account
      password: your-password
      mark_read: 1

=head1 DESCRIPTION

This plugin allows you to synchronize your subscription using
Bloglines Web Services sync API.

=head1 CONFIGURATION

=over 4

=item username, password

Your username & password to use with Bloglines API.

=item mark_read

C<mark_read> specifies whether this plugin "marks as read" the items
you synchronize. Without this option, you will get the duplicated
updates everytime you run Plagger, until you mark them unread using
Bloglines browser interface. Defaults to 1.

Setting this to 0 is recommended only for testing, or users who don't
use Publish::Gmail plugin.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<WebService::Bloglines>, L<http://www.bloglines.com/>

=cut

