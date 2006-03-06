package Plagger::Plugin::Aggregator::Simple;
use strict;
use base qw( Plagger::Plugin );

use Plagger::UserAgent;
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

    my $agent    = Plagger::UserAgent->new;
    my $response = $agent->fetch($url, $self);

    if ($response->is_error) {
        $context->log(error => "GET $url failed: " .
                      $response->http_status . " " .
                      $response->http_response->message);
        return;
    }

    # TODO: handle 301 Moved Permenently and 410 Gone
    $context->log(debug => $response->status . ": $url");

    my $args = { content => $response->content };
    Plagger->context->run_hook('aggregator.filter.feed', $args);

    $self->handle_feed($url, \$args->{content});
}

sub handle_feed {
    my($self, $url, $xml_ref) = @_;

    my $context = Plagger->context;
    my $remote = eval { XML::Feed->parse($xml_ref) };

    unless ($remote) {
        $context->log(error => "Parsing $url failed. " . ($@ || XML::Feed->errstr));
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
    $feed->source_xml($$xml_ref);

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

        my $category = $e->category;
           $category = [ $category ] if $category && !ref($category);
        $entry->tags($category) if $category;

        $entry->date( Plagger::Date->rebless($e->issued) )
            if eval { $e->issued };
        $entry->link($e->link);
        $entry->id($e->id);
        $entry->body($e->content->body);

        $entry->{feed_entry} = $e; # xxx for now

        $feed->add_entry($entry);
    }

    $context->log(info => "Aggregate $url success: " . $feed->count . " entries.");
    $context->update->add($feed);
}

1;

__END__

=head1 NAME

Plagger::Plugin::Aggregator::Simple - Dumb simple aggregator

=head1 SYNOPSIS

  - module: Aggregator::Simple

=head1 DESCRIPTION

This plugin implements a Plagger dumb aggregator. It crawls
subscription sequentially and parses XML feeds using L<XML::Feed>
module.

It can be also used as a base class for custom aggregators. See
L<Plagger::Plugin::Aggregator::Xango> for example.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<XML::Feed>, L<XML::RSS::LibXML>

=cut
