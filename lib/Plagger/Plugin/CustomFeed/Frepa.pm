package Plagger::Plugin::CustomFeed::Frepa;
use strict;
use base qw( Plagger::Plugin );

use DateTime::Format::Strptime;
use Encode;
use Time::HiRes;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'subscription.load' => \&load,
        'aggregator.aggregate.frepa' => \&aggregate,
    );
}

sub load {
    my($self, $context) = @_;
    $self->{frepa} = Plagger::Plugin::CustomFeed::Frepa::Mechanize->new($self->conf->{livedoor_id}, $self->conf->{password});

    my $feed = Plagger::Feed->new;
    $feed->type('frepa');
    $context->subscription->add($feed);
}

sub aggregate {
    my($self, $context, $args) = @_;


    unless ($self->{frepa}->login) {
	$context->log(error => "Login failed.");
        return;
    }

    $context->log(info => 'Login to frepa succeed.');

    my $feed = Plagger::Feed->new;
    $feed->type('frepa');
    $feed->title('フレパ最新日記');
    $feed->link('http://frepa.jp/home/friend_blog/');

    my $format = DateTime::Format::Strptime->new(pattern => '%Y/%m/%d %H:%M');

    my @msgs = $self->{frepa}->get_new_friend_diary;
    my $items = $self->conf->{fetch_items} || 20;

    my $i = 0;
    my $blocked = 0;
    for my $msg (@msgs) {
        last if $i++ >= $items;

        my $entry = Plagger::Entry->new;
        $entry->title( decode('euc-jp', $msg->{subject}) );
        $entry->link($msg->{link});
        $entry->author( decode('euc-jp', $msg->{name}) );
        $entry->date( Plagger::Date->parse($format, $msg->{time}) );

        if ($self->conf->{fetch_body} && !$blocked) {
            $context->log(info => "Fetch body from $msg->{link}");
            Time::HiRes::sleep( $self->conf->{fetch_body_interval} || 1.5 );
            my($item) = $self->{frepa}->get_view_diary($msg->{link});
            if ($item) {
                my $body = decode('euc-jp', $item->{description});
                   $body =~ s!<br>!<br />!g;
                $entry->body($body);
                $entry->title( decode('euc-jp', $item->{subject}) ); # replace with full title
            } else {
                $context->log(warn => "Fetch body failed. You might be blocked?");
                $blocked++;
            }
        }

        if ($self->conf->{show_icon} && !$blocked) {
            my $item = $self->fetch_icon($msg->{user_link});
            if ($item && $item->{image} !~ /no_photo/) {
                $entry->icon({
                    title => decode('euc-jp', $item->{name}),
                    url   => $item->{image},
                    link  => $msg->{user_link},
                });
            }
        }

        $feed->add_entry($entry);
    }

    $context->update->add($feed);
}

sub fetch_icon {
    my($self, $url) = @_;

    unless ($self->{__icon_cache}->{$url}) {
        Plagger->context->log(info => "Fetch icon from $url");
        $self->{__icon_cache}->{$url} = $self->{frepa}->get_top($url);
    }

    $self->{__icon_cache}->{$url};
}

package Plagger::Plugin::CustomFeed::Frepa::Mechanize;

use strict;
use WWW::Mechanize;

sub new {
    my $class = shift;

    bless {
	mecha       => WWW::Mechanize->new,
	livedoor_id => shift,
	password    => shift,

        login_url => 'http://member.livedoor.com/login/?.next=http%3A%2F%2Ffrepa.livedoor.com&.sv=frepa&.nofrepa=1',
    }, $class;
}

sub login {
    my $self = shift;

    my $res = $self->{mecha}->get($self->{login_url});
    return 0 unless $self->{mecha}->success;

    $self->{mecha}->set_fields(livedoor_id => $self->{livedoor_id}, password => $self->{password});
    my $res = $self->{mecha}->submit;
    return 0 unless $self->{mecha}->success;

    return 1;
}

sub get_new_friend_diary {
    my $self = shift;

    my @msgs = ();
    my $res = $self->{mecha}->follow_link(url_regex => qr{/friend_blog/});
    return @msgs unless $self->{mecha}->success;

    my $html = $self->{mecha}->content;
    my $reg = $self->list_regexp();
    while ($html =~ m|$reg|igs) {
	my $time = "$1/$2/$3 $4:$5";
	my ($link, $subject, $user_link, $name) =
	    ($self->unescape($6), $self->unescape($7), $self->unescape($8), $self->unescape($9));

	push(@msgs, +{
	    link => $link,
	    subject => $subject,
	    name => $name,
	    user_link => $user_link,
	    time => $time,
	});
    }
    return @msgs;
}

sub get_view_diary {
    my $self = shift;
    my $link = shift;

    my $item;
    my $res = $self->{mecha}->get($link);
    return $item unless $self->{mecha}->success;

    my $html = $self->{mecha}->content;
    my $reg = $self->detail_regexp();
    if ($html =~ m|$reg|is) {
        $item = +{ subject => $6, description => $7};
    }

    return $item;
}

sub get_top {
    my $self = shift;
    my $link = shift;

    my $item;
    my $res = $self->{mecha}->get($link);
    return $item unless $self->{mecha}->success;

    my $html = $self->{mecha}->content;

    chomp( my $re  = $self->top_re );
    if ($html =~ /$re/s) {
        $item->{image} = $1;
        $item->{name}  = $2;
    }

    return $item;
}

sub unescape {
    my $self = shift;                                                                                                                         
    my $str  = shift;
    my %unescaped = ('amp' => '&', 'quot' => '"', 'gt' => '>', 'lt' => '<', 'nbsp' => ' ', 'apos' => "'", 'copy' => '(c)');
    my $re_target = join('|', keys(%unescaped));
    $str =~ s/&($re_target|#x([0-9a-z]+));/defined($unescaped{$1}) ? $unescaped{$1} : defined($2) ? chr(hex($2)) : "&$1;"/ige;
    return $str;
}

sub list_regexp {
    return <<'RE';
<tr class="bgwhite">
<td width="1%" style="padding:5px 30px;" nowrap><small>(\d\d\d\d)..(\d\d)..(\d\d).. (\d\d):(\d\d)</small></td>
<td width="99%"><img src="/img/icon/diary_fp.gif" border="0" alt=".*?" title=".*?">
<small>



<a href="([^"]+?/blog/show[^"]+?)">(.*?)</a>.*?
<a href="([^"]+?)">([^"]+?)</a>.*?
RE
}

sub detail_regexp {
    return <<'RE';
<td width="105" valign="top" rowspan="3" class="bg2 blogline1" nowrap><small>(\d\d\d\d)..(\d\d)..(\d\d)..<br>(\d\d):(\d\d)</small></td>
<td width="445" class="bg2 blogline3 blogcell"><small><strong>(.*?)</strong></small></td>
</tr>
<tr>
<td class="bgwhite blogline2" style="line-height:115%;border-bottom:1px solid #fff;"><small>(.*?)</small></td>
</tr>

</table>
RE
;
}

sub top_re {
    return <<'RE';
<a href="http://frepa\.livedoor\.com/.*?/"><img src="(http://img\d+\.ico\.frepa\.livedoor\.com/member_photo/.*?\.(?:jpe?g|JPE?G|gif|GIF))" border="0"></a>
</small>
.*?
<div id="namebody"><small><strong>(.*?)....</strong>
RE
}

1;

__END__

=head1 NAME

Plagger::Plugin::CustomFeed::Frepa - Custom feed for livedoor Frepa

=head1 SYNOPSIS

  - module: CustomFeed::Frepa
    config:
      livedoor_id: your-id
      password: password
      fetch_body: 1
      show_icon: 1

=head1 DESCRIPTION

This plugin fetches your friend blog updates from livedoor Frepa
(L<http://frepa.livedoor.com/>) and creates a custom feed.

=head1 CONFIGURATION

See L<Plagger::Plugin::CustomFeed::Mixi> for C<fetch_body>,
C<fetch_body_interval> and C<show_icon>.

=head1 AUTHOR

Kazuhiro Osawa

=head1 SEE ALSO

L<Plagger>, L<Plagger::Plugin::CustomFeed::Mixi>, L<WWW::Mechanize>,
L<http://frepa.livedoor.com/>

=cut
