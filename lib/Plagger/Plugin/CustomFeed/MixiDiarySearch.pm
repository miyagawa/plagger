package Plagger::Plugin::CustomFeed::MixiDiarySearch;
use strict;
use base qw( Plagger::Plugin );

use Encode;
use HTML::Entities;
use Plagger::UserAgent;
use Plagger::Util qw( decode_content );

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'customfeed.handle' => \&handle,
    );
}

sub handle {
    my($self, $context, $args) = @_;

    if ($args->{feed}->url =~ m!^http://mixi\.jp/search_diary\.pl\?.*keyword=!) {
        $self->aggregate($context, $args);
        return 1;
    }

    return;
}

sub aggregate {
    my($self, $context, $args) = @_;

    my $url = $args->{feed}->url;
    $context->log(info => "GET $url");

    my $agent = Plagger::UserAgent->new;
    my $res = $agent->fetch($url, $self);

    if ($res->is_error) {
        $context->log(error => "GET $url failed: " . $res->status_code);
        return;
    }

    my $content = decode_content($res);

    my %query = URI->new($url)->query_form;

    # heh, this is a "Cache"
    my $title = "mixi: Search for " . decode("euc-jp", $query{keyword});
    if (!$self->conf->{mixi_tos_paranoia}) {
        $title .= " (Cache)";
    }

    my $feed = $args->{feed};
    $feed->title($title);
    $feed->link($url);

    my $re = decode('utf-8', <<'RE');
<table BORDER=0 CELLSPACING=1 CELLPADDING=4 WIDTH=550>
<tr>
<td WIDTH=90 VALIGN=top ROWSPAN=5 ALIGN=center background=http://img\.mixi\.jp/img/bg_line\.gif><a href="(view_diary\.pl\?id=\d+&owner_id=\d+)"><img SRC="(http://img-p\d+\.mixi\.jp/photo/member/.*?\.\w+)" VSPACE=3 border=0></a></td>
<td BGCOLOR=#FDF9F2><font COLOR=#996600>名&nbsp;&nbsp;前</font></td>
<td COLSPAN=2 BGCOLOR=#FFFFFF>(.*?)

</td></tr>

<tr>
<td BGCOLOR=#FDF9F2><font COLOR=#996600>タイトル</font></td>
<td COLSPAN=2 BGCOLOR=#FFFFFF>(.*?)</td></tr>

<tr>
<td BGCOLOR=#FDF9F2><font COLOR=#996600>本&nbsp;&nbsp;文</font></td>
<td COLSPAN=2 BGCOLOR=#FFFFFF>(.*?)</td></tr>


<tr>
<td NOWRAP BGCOLOR=#FDF9F2 WIDTH=80><font COLOR=#996600>作成日時</font></td>
<td BGCOLOR=#FFFFFF WIDTH=220>(\d\d月\d\d日 \d\d:\d\d)</td>
RE

    $content =~ s/\r\n/\n/g;

    my @matches;
    my @keys = qw( link photo name title body date );
    my $date_format = decode("utf-8", "%Y %m月%d日 %H:%M");

    while ($content =~ /$re/gs) {
        my $data;
        @{$data}{@keys} = ($1, $2, $3, $4, $5, $6);

        my $now = Plagger::Date->now;
        my $current = $now->year;
        $data->{date} = Plagger::Date->strptime($date_format, "$current $data->{date}");

        $data->{date}->set_time_zone('Asia/Tokyo'); # set floating datetime

        # one year ago, if the parsed datetime is in the future
        if ($data->{date} > $now) {
            $data->{date}->subtract(years => 1);
        }

        $data->{date}->set_time_zone(Plagger->context->conf->{timezone} || 'local');

        my $entry = Plagger::Entry->new;

        $entry->title($data->{title});
        $entry->link( URI->new_abs($data->{link}, $url) );
        $entry->date($data->{date});

        unless ($self->conf->{mixi_tos_paranoia}) {
            $entry->body( munge_body($data->{body}) );
            $entry->icon({ url => URI->new_abs($data->{photo}, $url) });
            $entry->author( decode_entities($data->{name}) );
        }

        $feed->add_entry($entry);
    }

    $context->update->add($feed);
}

sub munge_body {
    my $body = shift;
    $body =~ s/<br>//g;
    decode_entities($body);
}

1;

__END__

=head1 NAME

Plagger::Plugin::CustomFeed::MixiDiarySearch - Custom feed for mixi diary search

=head1 SYNOPSIS

  global:
    user_agent:
      cookies: /path/to/cookies.txt

  plugins:
    - module: Subscription::Config
      config:
        feed:
          - http://mixi.jp/search_diary.pl?submit=search&keyword=Plagger
    - module: CustomFeed::MixiDiarySearch

=head1 DESCRIPTION

This plugin creates a custom feed off of Mixi diary search. Since mixi
requires login authentication for all pages, this plugin also requires
a valid login cookie set to global I<user_agent> config.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<http://mixi.jp/>

=cut
