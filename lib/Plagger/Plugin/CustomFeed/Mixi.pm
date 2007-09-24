package Plagger::Plugin::CustomFeed::Mixi;
use strict;
use base qw( Plagger::Plugin );

use DateTime::Format::Strptime;
use Encode;
use WWW::Mixi;
use Time::HiRes;
use URI;

our $MAP = {
    FriendDiary => {
        start_url  => 'http://mixi.jp/new_friend_diary.pl',
        title      => 'マイミク最新日記',
        get_list   => 'parse_new_friend_diary',
        get_detail => 'get_view_diary',
        icon_re    => qr/owner_id=(\d+)/,
    },
    # can't get icon
    Message => {
        start_url  => 'http://mixi.jp/list_message.pl',
        title      => 'ミクシィメッセージ受信箱',
        get_list   => 'parse_list_message',
        get_detail => 'get_view_message',
    },
    # can't get icon & body
    RecentComment => {
        start_url  => 'http://mixi.jp/list_comment.pl',
        title      => 'ミクシィ最近のコメント一覧',
        get_list   => 'parse_list_comment',
    },
    Log => {
        start_url  => 'http://mixi.jp/show_log.pl',
        title      => 'ミクシィ足跡',
        get_list   => 'parse_show_log',
        icon_re    => qr/[^_]id=(\d+)/,
    }, 
    MyDiary => {
        start_url  => 'http://mixi.jp/list_diary.pl',
        title      => 'ミクシィ日記',
        get_list   => 'parse_list_diary',
        get_detail => 'get_view_diary',
        icon_re    => qr/owner_id=(\d+)/,
    },
    Calendar => {
        start_url  => 'http://mixi.jp/show_calendar.pl',
        title      => 'ミクシィカレンダー',
        get_list   => 'parse_show_calendar',
        get_detail => 'get_view_event',
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

    $self->{mixi} = WWW::Mixi->new($self->conf->{email}, $self->conf->{password});
    $self->{mixi}->cookie_jar($cookie_jar);

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

    my $start_url = $MAP->{$type}->{start_url};
    my $response  = $self->{mixi}->get($start_url);

    my $next_url = URI->new($start_url)->path;

    if ($response->content =~ /action="\/login\.pl"/) {
        $context->log(debug => "Cookie not found. Logging in");

        if ($self->conf->{email} eq 'plagger@localhost') {
            $context->log(error => 'email/password should be set to login');
        }

        $response = $self->{mixi}->post("http://mixi.jp/login.pl", {
            next_url => $next_url,
            email    => $self->conf->{email},
            password => $self->conf->{password},
            sticky   => 'on',
        });
        if (!$response->is_success || $response->content =~ /action=\/login\.pl/) {
            $context->log(error => "Login failed.");
            return;
        }

        # meta refresh, ugh!
        if ($response->content =~ m!"0;url=(.*?)"!) {
            $response = $self->{mixi}->get($1);
        }
    }

    my $feed = Plagger::Feed->new;
    $feed->type('mixi');
    $feed->title($MAP->{$type}->{title});
    $feed->link($MAP->{$type}->{start_url});

    my $format = DateTime::Format::Strptime->new(pattern => '%Y/%m/%d %H:%M');

    my $meth = $MAP->{$type}->{get_list};
    my @msgs = $self->{mixi}->$meth($response);
    my $items = $self->conf->{fetch_items} || 20;
    $self->log(info => 'fetch ' . scalar(@msgs) . ' entries');

    my $i = 0;
    my $blocked = 0;
    for my $msg (@msgs) {
        next if $type eq 'FriendDiary' and not $msg->{image}; # external blog
        last if $i++ >= $items;

        my $entry = Plagger::Entry->new;
        $entry->title( decode('euc-jp', $msg->{subject}) );
        $entry->link($msg->{link});
        $entry->author( decode('euc-jp', $msg->{name}) );
        $entry->date( Plagger::Date->parse($format, $msg->{time}) );

        if ($self->conf->{show_icon} && !$blocked && defined $MAP->{$type}->{icon_re}) {
            my $owner_id = ($msg->{link} =~ $MAP->{$type}->{icon_re})[0];
            my $link = "http://mixi.jp/show_friend.pl?id=$owner_id";
            $context->log(info => "Fetch icon from $link");

            my $item = $self->cache->get_callback(
                "outline-$owner_id",
                sub {
                    Time::HiRes::sleep( $self->conf->{fetch_body_interval} || 1.5 );
                    my($item) = $self->{mixi}->get_show_friend_outline($link);
                    $item;
                },
                '12 hours',
            );
            if ($item && $item->{image} !~ /no_photo/) {
                # prefer smaller image
                my $image = $item->{image};
                   $image =~ s/\.jpg$/s.jpg/;
                $entry->icon({
                    title => decode('euc-jp', $item->{name}),
                    url   => $image,
                    link  => $link,
                });
            }
        }

        if ($self->conf->{fetch_body} && !$blocked && $msg->{link} =~ /view_/ && defined $MAP->{$type}->{get_detail}) {
            $context->log(info => "Fetch body from $msg->{link}");
            my $item = $self->cache->get_callback(
                "item-$msg->{link}",
                sub {
                    Time::HiRes::sleep( $self->conf->{fetch_body_interval} || 1.5 );
                    my $meth = $MAP->{$type}->{get_detail};
                    my($item) = $self->{mixi}->$meth($msg->{link});

                    if ($meth eq 'get_view_diary') {
                        $item->{images} = $self->get_images($self->{mixi}->response->content);
                    }
                    $item;
                },
                '12 hours',
            );
            if ($item) {
                my $body = decode('euc-jp', $item->{description});
                   $body =~ s!(\r\n?|\n)!<br />!g;
                for my $image (@{ $item->{images} }) {
                    $body .= qq(<div><a href="$image->{link}"><img src="$image->{thumb_link}" style="border:0" /></a></div>);
                    my $enclosure = Plagger::Enclosure->new;
                    $enclosure->url( URI->new($image->{thumb_link}) );
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

sub get_images {
    my($self, $content) = @_;

    my @images;
    while ($content =~ m!MM_openBrWindow\('(show_diary_picture\.pl\?.*?)',.*?><img src="(http://ic\d+\.mixi\.jp/p/.*?)"!g) {
        push @images, { link => "http://mixi.jp/$1", thumb_link => $2 };
    }

    return \@images;
}

1;

__END__

=head1 NAME

Plagger::Plugin::CustomFeed::Mixi -  Custom feed for mixi.jp

=head1 SYNOPSIS

    - module: CustomFeed::Mixi
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

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<WWW::Mixi>

=cut
