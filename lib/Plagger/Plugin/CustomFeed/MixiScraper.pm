package Plagger::Plugin::CustomFeed::MixiScraper;
use strict;
use base qw( Plagger::Plugin );

use DateTime::Format::Strptime;
use WWW::Mixi::Scraper;
use Time::HiRes;

our $MAP = {
    FriendDiary => {
        title      => 'マイミク最新日記',
        get_list   => 'new_friend_diary',
        get_detail => 'view_diary',
        icon       => 'owner_id',
    },
    # can't get icon
    Message => {
        title      => 'ミクシィメッセージ受信箱',
        get_list   => 'list_message',
        get_detail => 'view_message',
    },
    # can't get icon & body
    RecentComment => {
        title      => 'ミクシィ最近のコメント一覧',
        get_list   => 'list_comment',
    },
    Log => {
        title      => 'ミクシィ足跡',
        get_list   => 'show_log',
        icon       => 'id',
    }, 
    MyDiary => {
        title      => 'ミクシィ日記',
        get_list   => 'list_diary',
        get_detail => 'view_diary',
        icon       => 'owner_id',
    },
    Calendar => {
        title      => 'ミクシィカレンダー',
        get_list   => 'show_calendar',
        get_detail => 'view_event',
    },
};

sub plugin_id {
    my $self = shift;
    $self->class_id . '-' . $self->conf->{email};
}

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'subscription.load' => \&load,
    );
}

sub load {
    my($self, $context) = @_;

    my $cookie_jar = $self->cookie_jar;
    if (ref($cookie_jar) ne 'HTTP::Cookies') {
        # using foreign cookies = don't have to set email/password. Fake them
        $self->conf->{email}    ||= 'plagger@localhost';
        $self->conf->{password} ||= 'pl4gg5r';
    }

    $self->{mixi} = WWW::Mixi::Scraper->new(
      email => $self->conf->{email},
      password => $self->conf->{password},
      cookie_jar => $cookie_jar,
    );

    my $feed = Plagger::Feed->new;
       $feed->aggregator(sub { $self->aggregate(@_) });
    $context->subscription->add($feed);
}

sub aggregate {
    my($self, $context, $args) = @_;
    for my $type (@{$self->conf->{feed_type} || ['FriendDiary']}) {
        $context->error("$type not found") unless $MAP->{$type};
        $self->aggregate_feed($context, $type, $args);
    }
}
sub aggregate_feed {
    my($self, $context, $type, $args) = @_;

    my $feed = Plagger::Feed->new;
    $feed->type('mixi');
    $feed->title($MAP->{$type}->{title});

    my $format = DateTime::Format::Strptime->new(pattern => '%Y-%m-%d %H:%M');

    my $meth = $MAP->{$type}->{get_list};
    my @msgs = $self->{mixi}->$meth->parse;
    my $items = $self->conf->{fetch_items} || 20;
    $self->log(info => 'fetch ' . scalar(@msgs) . ' entries');

    $feed->link($self->{mixi}->{mech}->uri);

    my $i = 0;
    my $blocked = 0;
    for my $msg (@msgs) {
        next if $type eq 'FriendDiary' and $msg->{link}->query_param('url'); # external blog
        last if $i++ >= $items;

        my $entry = Plagger::Entry->new;
        $entry->title($msg->{subject});
        $entry->link($msg->{link});
        $entry->author($msg->{name});
        $entry->date( Plagger::Date->parse($format, $msg->{time}) );

        if ($self->conf->{show_icon} && !$blocked && defined $MAP->{$type}->{icon}) {
            my $owner_id = $msg->{link}->query_param($MAP->{$type}->{icon});
            $context->log(info => "Fetch icon of id=$owner_id");

            my $item = $self->cache->get_callback(
                "outline-$owner_id",
                sub {
                    Time::HiRes::sleep( $self->conf->{fetch_body_interval} || 1.5 );
                    my $item = $self->{mixi}->show_friend->parse(id => $owner_id)->{outline};
                    $item;
                },
                '12 hours',
            );
            if ($item && $item->{image} !~ /no_photo/) {
                # prefer smaller image
                my $image = $item->{image};
                   $image =~ s/\.jpg$/s.jpg/;
                $entry->icon({
                    title => $item->{name},
                    url   => $image,
                    link  => $item->{link},
                });
            }
        }

        if ($self->conf->{fetch_body} && !$blocked && $msg->{link} =~ /view_/ && defined $MAP->{$type}->{get_detail}) {
            $context->log(info => "Fetch body from $msg->{link}");
            my $item = $self->cache->get_callback(
                "item-$msg->{link}",
                sub {
                    Time::HiRes::sleep( $self->conf->{fetch_body_interval} || 1.5 );
                    my $item = $self->{mixi}->parse($msg->{link});
                    $item;
                },
                '12 hours',
            );
            if ($item) {
                my $body = $item->{description};
                   $body =~ s!(\r\n?|\n)!<br />!g;
                for my $image (@{ $item->{images} || [] }) {
                    $body .= qq(<div><a href="$image->{link}"><img src="$image->{thumb_link}" style="border:0" /></a></div>);
                    my $enclosure = Plagger::Enclosure->new;
                    $enclosure->url($image->{thumb_link});
                    $enclosure->auto_set_type;
                    $enclosure->is_inline(1);
                    $entry->add_enclosure($enclosure);
                }
                $entry->body($body);

                $entry->date( Plagger::Date->parse($format, $item->{time}) );
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

__END__

=head1 NAME

Plagger::Plugin::CustomFeed::MixiScraper -  Custom feed for mixi.jp

=head1 SYNOPSIS

    - module: CustomFeed::MixiScraper
      config:
        email: email@example.com
        password: password
        fetch_body: 1
        show_icon: 1
        feed_type:
          - RecentComment
          - FriendDiary
          - Message

=head1 DESCRIPTION

This plugin fetches your friends diary updates from mixi
(L<http://mixi.jp/>) and creates a custom feed.

=head1 CONFIGURATION

=over 4

=item email, password

Credential you need to login to mixi.jp.

Note that you don't have to supply email and password if you set
global cookie_jar in your configuration file and the cookie_jar
contains a valid login session there, such as:

  global:
    user_agent:
      cookies: /path/to/cookies.txt

See L<Plagger::Cookies> for details.

=item fetch_body

With this option set, this plugin fetches entry body HTML, not just a
link to the entry. Defaults to 0.

=item fetch_body_interval

With C<fetch_body> option set, your Plagger script is recommended to
wait for a little, to avoid mixi.jp throttling. Defaults to 1.5.

=item show_icon: 1

With this option set, this plugin fetches users buddy icon from
mixi.jp site, which makes the output HTML very user-friendly.

=item feed_type

With this option set, you can set the feed types.

Now supports: RecentComment, FriendDiary, Message, Log, MyDiary, and Calendar.

Default: FriendDiary.

=back

=head1 SCREENSHOT

L<http://blog.bulknews.net/mt/archives/plagger-mixi-icon.gif>

=head1 AUTHOR

Tatsuhiko Miyagawa, modified by Kenichi Ishigaki

=head1 SEE ALSO

L<Plagger>, L<WWW::Mixi::Scraper>

=cut
