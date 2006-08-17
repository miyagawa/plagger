package Plagger::Plugin::Filter::Delicious;
use strict;
use base qw( Plagger::Plugin );

use Digest::MD5 qw(md5_hex);
use Plagger::UserAgent;
use XML::Feed;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'update.entry.fixup' => \&update,
    );
}

sub update {
    my($self, $context, $args) = @_;

    my $interval = $self->conf->{interval} || 1;
    sleep $interval;

    my $md5  = md5_hex($args->{entry}->permalink);
    my $url  = "http://del.icio.us/rss/url/$md5";

    $self->log(info => "Going to fetch $url");

    my $ua = Plagger::UserAgent->new;
       $ua->timeout(30);

    my $res  = $ua->fetch($url);

    if ($res->is_error) {
        $self->log(error => "Fetch URL $url failed.");
        return;
    }

    my $feed = XML::Feed->parse(\$res->content);

    unless ($feed) {
        $context->log(warn => "Feed error $url: " . XML::Feed->errstr);
        return;
    }

    for my $entry ($feed->entries) {
        my @tag = split / /, ($entry->category || '');
           @tag or next;

        for my $tag (@tag) {
            $args->{entry}->add_tag($tag);
        }
    }

    my $delicious_users = $feed->entries;
    if ($delicious_users >= 30 && $self->conf->{scrape_big_numbers}) {
        my $url = "http://del.icio.us/url/$md5";
        $self->log(info => "users count is more than 30. Trying to scrape from $url.");
        sleep $interval;

        my $res = $ua->fetch($url);

        if ($res->is_error) {
            $context->log(warn => "Fetch error $url: " . $res->http_response->message);
            return;
        }

        $delicious_users =
            ( $res->content =~ m#<h4[^>]*>[^<>]*this url has been saved by\D+(\d+)#s )[0];
    }
    $args->{entry}->meta->{delicious_rate} = rate_of_color($delicious_users);
    $args->{entry}->meta->{delicious_users} = $delicious_users;
    $self->log(info => "set delicious_users to $delicious_users");
}

sub rate_of_color {
    my $n = shift;
    return 100 unless $n;
    int(log($n) / log(0.82) + 100);
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::Delicious - Fetch tags and users count from del.icio.us

=head1 SYNOPSIS

  - module: Filter::Delicious

=head1 DESCRIPTION

B<Note: this module is mostly untested and written just for a proof of
concept. If you run this on your box with real feeds, del.icio.us wlil
be likely to ban your IP. See http://del.icio.us/help/ for details.>

This plugin queries del.icio.us using its RSS feeds API to get the
tags people added to the entries, and how many people bookmarked them.

Users count is stored in C<delicious_users> metadata of
Plagger::Entry, so that other plugins and smartfeeds can make use of.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<http://del.icio.us/help/>

=cut
