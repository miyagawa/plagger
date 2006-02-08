package Plagger::Plugin::CustomFeed::Mailman;
use strict;
use base qw( Plagger::Plugin );

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
        or $context->error("pipemail url not set");

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
    my $title = ($content =~ /<title>(.*?) $year/)[0]; # xxx hack

    my $feed = Plagger::Feed->new;
    $feed->type('mailman');
    $feed->title($title);
    $feed->link($self->conf->{url}); # base

    my $i = 0;
    my $items = $self->conf->{fetch_items} || 20;
    while ($content =~ m!<LI><A HREF="(\d+\.html)">(.*?)\n</A><A NAME="(\d+)">&nbsp;</A>\n<I>(.*?)\n</I>!g) {
        last if $i++ >= $items;

        my($link, $subject, $id, $from) = ($1, $2, $3, $4);
        if ($self->conf->{trim_prefix}) {
            # don't use $id here. Some Re: messages contain original ID
            $subject =~ s/\[$title \d+\]\s+//;
        }

        my $entry = Plagger::Entry->new;
        $entry->title($subject);
        $entry->link($base_url . $link);
        $entry->author($from);

        $feed->add_entry($entry);
    }

    $context->update->add($feed);
}

1;

