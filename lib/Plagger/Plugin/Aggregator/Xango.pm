# $Id$
#
# Copyright (c) 2006 Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

package Plagger::Plugin::Aggregator::Xango;
use strict;
use base qw( Plagger::Plugin );
use POE;
use Xango::Broker::Push;
# sub Xango::DEBUG { 1 } # uncomment to get Xango debug messages

sub register {
    my($self, $context) = @_;

    my %xango_args = (
        Alias => 'xgbroker',
        HandlerAlias => 'xghandler',
        %{$self->conf->{xango_args} || {}},
    );
    $self->{xango_alias} = $xango_args{Alias};
    Plagger::Plugin::Aggregator::Xango::Crawler->spawn(
        Context => $context,
    );
    Xango::Broker::Push->spawn(%xango_args);
    $context->register_hook(
        $self,
        'aggregator.aggregate.feed' => \&aggregate,
        'aggregator.finalize'       => \&finalize,
    );
}

sub aggregate {
    my($self, $context, $args) = @_;

    my $url = $args->{feed}->url;
    $context->log(info => "Fetch $url");
    POE::Kernel->post($self->{xango_alias}, 'enqueue_job', Xango::Job->new(uri => URI->new($url)));
}

sub finalize {
    my($self, $context, $args) = @_;
    POE::Kernel->run;
}
    
package Plagger::Plugin::Aggregator::Xango::Crawler;
use strict;
use POE;
use XML::Feed;

sub apply_policy { 1 }
sub spawn  {
    my $class = shift;
    my %args  = @_;

    POE::Session->create(
        heap => { CONTEXT => $args{Context} },
        package_states => [
            $class => [ qw(_start _stop apply_policy handle_response) ]
        ]
    );
}

sub _start { $_[KERNEL]->alias_set('xghandler') }
sub _stop  { }
sub handle_response {
    my $job = $_[ARG0];
    my $context = $_[HEAP]->{CONTEXT};

    my $r = $job->notes('http_response');
    my $url    = $job->uri;
    my $remote = eval { XML::Feed->parse($r->content_ref) };

    unless ($remote) {
        $context->log(info => "Parsing $url failed. $@");
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
        $entry->id($e->id);
        $entry->body($e->content->body);

        $feed->add_entry($entry);
    }

    $context->log(info => "Aggregate $url success: " . $feed->count . " entries.");
    $context->update->add($feed);
}

1;

