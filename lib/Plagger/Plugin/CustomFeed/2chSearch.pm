package Plagger::Plugin::CustomFeed::2chSearch;
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

    if ($args->{feed}->url =~ m!^http://find\.2ch\.net/index\.php\?.*TYPE=BODY!) {
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
    my $res = $agent->fetch($url, $self, { NoNetwork => 60 * 60 });

    if (!$res->status && $res->is_error) {
        $context->log(error => "GET $url failed: " . $res->status);
        return;
    }

    my $content = decode_content($res);

    my %query = URI->new($url)->query_form;
    my $query = decode("euc-jp", $query{STR});

    my $feed = $args->{feed};
    $feed->title( decode("utf-8", "2ch 検索: ") . $query );
    $feed->link($url);

    my $re = decode('utf-8', <<'RE');
<dt><a href="(.*?)"><b>(.*?)</b></a> \((\d+)\) - <font size=-1>.*?</font> - <font size=-1><a href=.*?</a>＠.*?</font></dt><dd>(.*?)<br><font color=\#228822>.*?鯖 / 最新:(\d{4}/\d\d/\d\d \d\d:\d\d)</font> - .*?</dd>
RE

    $content =~ s/\r\n/\n/g;

    my @matches;
    my @keys = qw( link title count body date );
    my $date_format = "%Y/%m/%d %H:%M";

    while ($content =~ /$re/gs) {
        my $data;
        @{$data}{@keys} = ($1, $2, $3, $4, $5);

        $data->{date} = Plagger::Date->strptime($date_format, $data->{date});
        $data->{date}->set_time_zone('Asia/Tokyo'); # set floating datetime
        $data->{date}->set_time_zone(Plagger->context->conf->{timezone} || 'local');

        $self->find_entry($data, $agent, $query);

        my $entry = Plagger::Entry->new;
        $entry->title($data->{title});
        $entry->link( URI->new_abs($data->{link}, $url) );
        $entry->date($data->{date});
        $entry->body( munge_body($data->{body}) );

        $feed->add_entry($entry);
    }

    $context->update->add($feed);
}

# mess with 2ch dat to find the actual entry, Ugggh
sub find_entry {
    my($self, $data, $agent, $query) = @_;

    # http://pc7.2ch.net/test/read.cgi/mac/1149563958/1-100
    # => http://pc7.2ch.net/mac/dat/1149563958.dat
    my($server, $board, $thread, $from, $to) =
        $data->{link} =~ m!^http://(\w+)\.2ch\.net/test/read\.cgi/([^/]+)/(\d+)/(\d+)-(\d+)!;
    my $dat = "http://$server.2ch.net/$board/dat/$thread.dat";

    Plagger->context->log(debug => "GET $dat to find true entry link");
    my $res = $agent->fetch($dat, $self);

    if (!$res->status && $res->is_error) {
        Plagger->context->log(error => "GET $dat failed: " . $res->status_code);
        return;
    }

    my $content = decode('shift_jis', $res->content);
    my @lines = split /\r?\n/, $content;

    # if it links to 101-200, search from 200 to 101 to find the newest one
    for my $id ( reverse ($from .. $to) ) {
        my $line = $lines[$id-1] or next;
        my @data = split /<>/, $line;
        if ($data[3] =~ /$query/i) {
            Plagger->context->log(info => "found entry on $id");
            # xxx I could update other metadata, but leave it for EntryFullText ...
            $data->{link} = "http://$server.2ch.net/test/read.cgi/$board/$thread/$id";

            if ($data[2] =~ m!^(\d{4}/\d\d/\d\d)\(.*?\) (\d\d:\d\d:\d\d)!) {
                $data->{date} = Plagger::Date->strptime("%Y/%m/%d %H:%M:%S", "$1 $2");
                $data->{date}->set_time_zone('Asia/Tokyo'); # set floating datetime
                $data->{date}->set_time_zone(Plagger->context->conf->{timezone} || 'local');
            }
            return;
        }
    }
}

sub munge_body {
    my $body = shift;
    $body =~ s!<b id=e\d+>(.*?)</b>!$1!g;
    decode_entities($body);
}

1;

__END__

=head1 NAME

Plagger::Plugin::CustomFeed::2chSearch - Custom feed for 2ch Search with Moritapo

=head1 SYNOPSIS

  global:
    user_agent:
      cookies: /path/to/cookies.txt

  plugins:
    - module: Subscription::Config
      config:
        feed:
          - http://find.2ch.net/index.php?BBS=2ch&TYPE=BODY&STR=Plagger&COUNT=10
    - module: CustomFeed::2chSearch

=head1 DESCRIPTION

This plugin creates a custom feed off of 2ch search
L<http://find.2ch.net/>. Since 2ch search requires Moritapo to search
by fulltext, this plugin also requires a valid login cookie set to
global I<user_agent> config.

=head1 FREQUENCY FOR SEARCHES

By default, this plugin doesn't search more than once in an hour by
default, to save your money (Moritapo). If you want to reduce seach
frequency more (like once in a day), consider using
L<Plagger::Rule::DateTimeCron> to trigger Subscription::Config for it.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<http://find.2ch.net/>

=cut
