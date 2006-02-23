package Plagger::Plugin::Aggregator::Simple;
use strict;
use base qw( Plagger::Plugin );

use URI;
use XML::Feed;
use XML::Feed::RSS;

$XML::Feed::RSS::PREFERRED_PARSER = 'XML::RSS::LibXML';

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'aggregator.aggregate.feed'  => \&aggregate,
    );
}

sub aggregate {
    my($self, $context, $args) = @_;

    my $url = $args->{feed}->url;
    $context->log(info => "Fetch $url");
    my $remote = eval { XML::Feed->parse(URI->new($url)) };

    unless ($remote) {
        $context->log(info => "Parsing $url failed. " . XML::Feed->errstr);
        next;
    }

    my $feed = Plagger::Feed->new;
    $feed->title($remote->title);
    $feed->url($url);
    $feed->link($remote->link);
    $feed->description($remote->tagline);
    $feed->language($remote->language);
    $feed->author($remote->author);
    $feed->updated($remote->modified);

    if ($remote->format eq 'Atom') {
        $feed->id( $remote->{atom}->id );
    }

    if ($remote->format =~ /^RSS/) {
        $feed->image( $remote->{rss}->image )
            if $remote->{rss}->image;
    } elsif ($remote->format eq 'Atom') {
        $feed->image({ url => $remote->{atom}->logo })
            if $remote->{atom}->logo;
    }

    for my $e ($remote->entries) {
        my $entry = Plagger::Entry->new;
        $entry->title($e->title);
        $entry->author($e->author);
        $entry->tags([ $e->category ]) if $e->category;
        $entry->date( Plagger::Date->rebless($e->issued) )
            if eval { $e->issued };
        $entry->link($e->link);
        $entry->id( $e->id ) if $e->id !~ m!^http://!;
        $entry->body($e->content->body);

        $feed->add_entry($entry);
    }

    $context->log(info => "Aggregate $url success: " . $feed->count . " entries.");
    $context->update->add($feed);
}

1;
