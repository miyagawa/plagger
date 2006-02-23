package Plagger::Plugin::CustomFeed::Mailman;
use strict;
use base qw( Plagger::Plugin );

use List::Util qw(min);
use DateTime::Locale;
use Encode;
use Plagger::UserAgent;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'subscription.load' => \&load,
        'aggregator.aggregate.mailman' => \&aggregate,
    );
}

sub load {
    my($self, $context) = @_;

    my $url = $self->conf->{url}
        or $context->error("pipermail url not set");

    my $feed = Plagger::Feed->new;
       $feed->type('mailman');
       $feed->url($url);
    $context->subscription->add($feed);
}

sub aggregate {
    my($self, $context, $args) = @_;

    my $url = $args->{feed}->url;
    $url .= '/' unless $url =~ m!/$!;

    my $now = Plagger::Date->now;
    $now->set_locale('en_us');

    my $base_url = $url . $now->year . '-' . $now->month_name . '/';

    $url = $base_url . 'date.html';
    $context->log(info => "GET $url");

    my $agent = Plagger::UserAgent->new;
    my $response = $agent->get($url);

    unless ($response->is_success) {
        $context->log(error => "GET $url failed: " . $response->status_line);
        return;
    }

    my $content = $response->content;
    my $encoding = ($content =~ /<META .*; charset=([\w\-]*)/)[0] || 'utf-8';

    eval {
        $content = decode($encoding, $content);
    };
    if ($@) {
        $context->log(warn => $@);
    }

    my $year  = $now->year;

    # TODO: only tested with ja and en localization
    my $month = join '|', @{ DateTime::Locale->load('en_us')->month_names };
    my $title = ($content =~ /<title>(?:The )?(.*?) (?:(?:$month) )?$year/)[0];

    my $feed = Plagger::Feed->new;
    $feed->type('mailman');
    $feed->title($title);
    $feed->link($args->{feed}->url); # base

    my @matches;
    while ($content =~ m!<LI><A HREF="(\d+\.html)">(.*?)\n</A><A NAME="(\d+)">&nbsp;</A>\n<I>(.*?)\n</I>!g) {
        push @matches, {
            link    => $1,
            subject => $2,
            id      => $3,
            from    => $4,
        };
    }

    my $items = min( $self->conf->{fetch_items} || 20, scalar(@matches));
    @matches  = reverse @matches[-$items .. -1];

    for my $match (@matches) {
        $match->{subject} =~ s/\[$title(?: \d+)?\]\s+//;

        my $entry = Plagger::Entry->new;
        $entry->title($match->{subject});
        $entry->link($base_url . $match->{link});
        $entry->author($match->{from});

        $feed->add_entry($entry);
    }

    $context->update->add($feed);
}

1;

