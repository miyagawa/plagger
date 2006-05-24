package Plagger::Plugin::CustomFeed::GoogleNews;
use strict;
use base qw( Plagger::Plugin );

use Plagger::UserAgent;
use Plagger::Util;
use URI;
use URI::QueryParam;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'customfeed.handle' => \&handle,
    );
}

sub handle {
    my($self, $context, $args) = @_;

    if ($args->{feed}->url =~ m!^http://news\.google\.(?:co\.jp|com)/! && $args->{feed}->url !~ /output=(?:rss|atom)/) {
        $self->aggregate($context, $args);
        return 1;
    }

    return;
}

sub aggregate {
    my($self, $context, $args) = @_;

    my $url = URI->new($args->{feed}->url);

    # ned=jp -> ned=tjp
    my $ned = $url->query_param('ned') || 'us';
       $ned = "t$ned" unless $ned =~ /^t/;
    $url->query_param(ned => $ned);

    $context->log(info => "GET $url");

    my $agent = Plagger::UserAgent->new;
    my $res = $agent->fetch($url, $self);

    if ($res->http_response->is_error) {
        $context->log(error => "GET $url failed: " . $res->status_line);
        return;
    }

    my $content = Plagger::Util::decode_content($res);
    my $title   = Plagger::Util::extract_title($content);

    my $feed = Plagger::Feed->new;
    $feed->title($title);
    $feed->link($args->{feed}->url);

    while ($content =~ m!<a href="(http://[^"]*)" id=r-\d[^>]*>(.*?)</a>!g) {
        my($link, $title) = ($1, $2);
        $title =~ s!<b>(.*?)</b>!$1!g;

        my $entry = Plagger::Entry->new;
        $entry->title($title);
        $entry->link($link);

        $feed->add_entry($entry);
    }

    $context->update->add($feed);
}

1;

__END__

=head1 NAME

Plagger::Plugin::CustomFeed::GoogleNews - Create Google News custom feed

=head1 SYNOPSIS

  - module: Subscription::Config
    config:
      feed:
        - http://news.google.com/news?ned=jp&rec=0&topic=s
        - http://news.google.co.jp/news?hl=ja&ned=jp&q=%E5%9B%B2%E7%A2%81

  - module: CustomFeed::GoogleNews

=head1 DESCRIPTION

This plugin creates a custom feed off of Google News HTML pages. Use
with EntryFullText plugin to get full content and accurate datetime of
articles.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>

=cut
