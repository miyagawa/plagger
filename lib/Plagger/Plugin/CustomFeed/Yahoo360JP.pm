package Plagger::Plugin::CustomFeed::Yahoo360JP;
use strict;
use base qw( Plagger::Plugin );

use DateTime::Format::Strptime;
use Encode;
use Time::HiRes;
use WWW::Mechanize;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'subscription.load' => \&load,
        'aggregator.aggregate.yahoo360jp' => \&aggregate,
    );
}

sub load {
    my($self, $context) = @_;

    my $feed = Plagger::Feed->new;
       $feed->type('yahoo360jp');
    $context->subscription->add($feed);
}

sub aggregate {
    my($self, $context, $args) = @_;

    my $start = "http://360.yahoo.co.jp/";

    my $mech = WWW::Mechanize->new(cookie_jar => $self->cache->cookie_jar);
    $mech->agent_alias( 'Windows IE 6' );
    $mech->get($start);

    if ($mech->content =~ /mgb_login/) {
	my $success;
	eval { $success = $self->login($mech) };

	if ($@ && $@ =~ /persistent/) {
	    $context->log(error => "Login failed. Clear cookie and redo.");
	    $mech->cookie_jar->clear;
	    $mech->get($start);
	    sleep 3;
	    eval { $success = $self->login($mech) };
	}

	return unless $success;
    }

    $context->log(info => "Login to Yahoo! succeeded.");

    my $feed = Plagger::Feed->new;
    $feed->type('yahoo360jp');
    $feed->title('Yahoo! 360');
    $feed->link('http://360.yahoo.co.jp/friends/content.html');

    # get friends blogs
    $mech->get("http://360.yahoo.co.jp/friends/content.html");

    # preserve link to blast page here ... used later
    my $link = $mech->find_link( url_regex => qr/form_submitted=friends_content_head/ );

    my $re = decode('utf-8', <<'RE');
<div class="mgc_pic">
<table><tr><td><a href="(http://360\.yahoo\.co\.jp/profile-.*?)" title="(.*?)"><img src="(http://.*?)"  alt=".*?" height="(\d+)" width="(\d+)" border="0"></a></td></tr></table>
</div>


<div class="mgc_txt">
<a href="(http://blog\.360\.yahoo\.co\.jp/blog-.*?)">(.*?)</a><br/>
<a href="http://360\.yahoo\.co\.jp/profile-.*?" title=".*?">.*?</a><span class="fixd_xs">&nbsp;さん</span><br>
<span class="fixd_xs">((\d+)月\d+日 \d\d:\d\d)</span>
</div>
<div class="clear"></div>
</div>
RE

    my $now = Plagger::Date->now;
    my $format = DateTime::Format::Strptime->new(pattern => decode('utf-8', '%Y %m月%d日 %H:%M'));

    my $content = decode('utf-8', $mech->content);
    while ($content =~ /$re/g) {
         my $args = {
             profile  => $1,
             nickname => $2,
             icon     => $3,
             height   => $4,
             width    => $5,
             link     => $6,
             title    => $7,
             date     => $8,
             month    => $9,
         };

         if ($self->conf->{fetch_body}) {
             my $item = $self->cache->get_callback(
                 "item-$args->{link}",
                 sub { $self->fetch_body($mech, $args->{link}) },
                 "1 hour",
             );
             $args->{body} = $item->{body} if $item->{body};
         }
         $self->add_entry($feed, $args, $now, $format);
    }

    $re = decode('utf-8', <<'RE');
<div class="mgc_pic">
<table><tr><td><a href="(http://360\.yahoo\.co\.jp/profile-.*?)" title="(.*?)"><img src="(http://.*?)"  alt=".*?" height="(\d\d)" width="(\d\d)" border="0"></a></td></tr></table>
</div>



<div class="mgc_txt">

<div class=".*?">

<div class="mgbp_blast_stxt">(?:<a href="(.*?)" target="new">(.*?)</a>|(.*?))</div>
<div class="mgbp_blast_sauthor"><span class="fixd_xs">((\d+)月\d+日 \d\d:\d\d)</span>&nbsp;&nbsp;<a href="http://360\.yahoo\.co\.jp/profile-.*?" title=".*?">.*?</a>&nbsp;<span class="fixd_xs">さん</span></div>
RE
    ;

    if ($link && $self->conf->{fetch_blast}) {
        $mech->get($link->url);
        my $content = decode('utf-8', $mech->content);
        while ($content =~ /$re/g) {
            $self->add_entry($feed, {
                profile  => $1,
                nickname => $2,
                icon     => $3,
                height   => $4,
                width    => $5,
                link     => $6 || $1,
                title    => $7 || $8,
                date     => $9,
                month    => $10,
            }, $now, $format);
        }
    } else {
        $context->log(error => "Can't find link to blast page.");
    }

    $feed->sort_entries;
    $context->update->add($feed);
}

sub login {
    my($self, $mech, $retry) = @_;

    $mech->submit_form(
        fields => {
            login  => $self->conf->{username},
            passwd => $self->conf->{password},
            '.persistent' => 'y',
        },
    );

    while ($mech->content =~ m!<span class="error">!) {
        Plagger->context->log(error => "Login to Yahoo! failed.");
        if ($mech->content =~ m!(https://captcha.yahoo.co.jp/img/.*\.jpg)!) {
            my $captcha = $self->prompt_captcha($1) or return;
            $mech->submit_form(
                fields => {
                    login  => $self->conf->{username},
                    passwd => $self->conf->{password},
                    '.secword'    => $captcha,
                    '.persistent' => 'y',
                },
            );
        } else {
            return;
        }
    }

    return 1;
}

sub add_entry {
    my($self, $feed, $args, $now, $format) = @_;

    # hack for seeing December entries in January
    my $year = $args->{month} > $now->month ? $now->year - 1 : $now->year;
    my $date = "$year $args->{date}";

    my $entry = Plagger::Entry->new;
    $entry->title($args->{title});
    $entry->link($args->{link});
    $entry->author($args->{nickname});
    $entry->date( Plagger::Date->parse($format, $date) );
    $entry->body($args->{body}) if $args->{body};

    $entry->icon({
        title  => $args->{nickname},
        url    => $args->{icon},
        link   => $args->{profile},
        width  => $args->{width},
        height => $args->{height},
    });

    $feed->add_entry($entry);
}

sub fetch_body {
    my($self, $mech, $link) = @_;

    Plagger->context->log(info => "Fetch body from $link");
    $mech->get($link);
    my $content = decode('utf-8', $mech->content);
    if ($content =~ m!<div id="mgbp_body">\n(.*?)</div>!sg) {
        return { body => $1 };
    }
    return;
}

sub prompt_captcha {
    my($self, $url) = @_;
    print STDERR "CAPTCHA:\n$url\nEnter the code: ";

    # use alarm timeout for cron job
    my $key;
    eval {
        local $SIG{ALRM} = sub { die "alarm\n" };
        alarm 30;
        chomp($key = <STDIN>);
        alarm 0;
    };
    return if $@;

    return $key;
}

1;

__END__

=head1 NAME

Plagger::Plugin::CustomFeed::Yahoo360JP - Yahoo! 360 JAPAN custom feed

=head1 SYNOPSIS

  - module: CustomFeed::Yahoo360JP
    config:
      username: your-yahoo-id
      password: xxxxxxxx
      fetch_body: 1
      fetch_blast: 1

=head1 DESCRIPTION

This plugin fetches your friends' blog updates and blast updates from
Yahoo! JAPAN 360 and make a custom feed off of them.

=head1 CONFIG

=over 4

=item username, password

Your Yahoo! ID and password to login.

=item fetch_body

Specifies whether this plugin fetches body of your friends' blog
entry. Defaults to 0.

=item fetch_blast

Specifies whether this plugin fetches a list of your friends'
blasts. Defaults to 0.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<WWW::Mechanize>, L<Plagger::Plugin::CustomFeed::Mixi>

=cut
