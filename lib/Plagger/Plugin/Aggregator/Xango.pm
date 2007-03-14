# $Id$
#
# Copyright (c) 2006 Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

package Plagger::Plugin::Aggregator::Xango;
use strict;
use base qw( Plagger::Plugin::Aggregator::Simple );
use Plagger::FeedParser;
use URI::Fetch;
use HTTP::Status;
use POE;
use Xango::Broker::Push;
# BEGIN { sub Xango::DEBUG { 1 } } # uncomment to get Xango debug messages

our $VERSION = '0.1';

sub register {
    my($self, $context) = @_;

    my %xango_args = (
        Alias => 'xgbroker',
        HandlerAlias => 'xghandler',
        HttpCompArgs => [
            Agent => $self->conf->{agent} || "Plagger/$Plagger::VERSION (http://plagger.org/)",
            Timeout => $self->conf->{timeout} || 10
        ],
        %{$self->conf->{xango_args} || {}},
    );
    $self->{xango_alias} = $xango_args{Alias};
    Plagger::Plugin::Aggregator::Xango::Crawler->spawn(
        Plugin => $self,
        UseCache => exists $self->conf->{use_cache} ?
            $self->conf->{use_cache} : 1,
        BrokerAlias => $xango_args{Alias},
        MaxRedirect => $self->conf->{max_redirect} || 3,
    );
    Xango::Broker::Push->spawn(%xango_args);
    $context->register_hook(
        $self,
        'customfeed.handle'   => \&aggregate,
        'aggregator.finalize' => \&finalize,
    );
}

sub aggregate {
    my($self, $context, $args) = @_;

    my $url = $args->{feed}->url;
    return unless $url =~ m!^https?://!i;

    $self->{_url2feed}->{$url} = $args->{feed}; # map from url to feed object

    $context->log(info => "Fetch $url");

    my $job = Xango::Job->new(
        uri => URI->new($url), 
        redirect => 0,
        is_original_request => 1
    );
    POE::Kernel->post($self->{xango_alias}, 'enqueue_job', $job);
}

sub handle_feed {
    my($self, $url, $xml_ref) = @_;
    $self->SUPER::handle_feed($url, $xml_ref, $self->{_url2feed}->{$url});
}

sub finalize {
    my($self, $context, $args) = @_;
    POE::Kernel->run;
}

package Plagger::Plugin::Aggregator::Xango::Crawler;
use strict;
use Feed::Find;
use POE;
use Storable qw(freeze thaw);
use XML::Feed;

sub apply_policy { 1 }
sub spawn  {
    my $class = shift;
    my %args  = @_;

    POE::Session->create(
        heap => {
            PLUGIN => $args{Plugin}, USE_CACHE => $args{UseCache},
            BROKER_ALIAS => $args{BrokerAlias},
            MaxRedirect => $args{MaxRedirect},
        },
        package_states => [
            $class => [ qw(_start _stop apply_policy prep_request handle_response) ]
        ]
    );
}

sub _start { $_[KERNEL]->alias_set('xghandler') }
sub _stop  { }
sub prep_request {
    return unless $_[HEAP]->{USE_CACHE};

    my $job = $_[ARG0];
    my $req = $_[ARG1];
    my $plugin = $_[HEAP]->{PLUGIN};

    my $ref = $plugin->cache->get($job->uri);
    if ($ref) {
        $req->if_modified_since($ref->{LastModified})
            if $ref->{LastModified};
        $req->header('If-None-Match', $ref->{ETag})
            if $ref->{ETag};
    }
}

sub handle_response {
    my $job = $_[ARG0];
    my $plugin = $_[HEAP]->{PLUGIN};

    my $redirect = $job->notes('redirect') + 1;
    return if $redirect > $_[HEAP]->{MaxRedirect};

    my $r = $job->notes('http_response');
    my $url    = $job->uri;
    if ($r->code =~ /^30[12]$/) {
        $url = $r->header('location');
        return unless $url =~ m!^https?://!i;
        $_[KERNEL]->post($_[HEAP]->{BROKER_ALIAS}, 'enqueue_job', Xango::Job->new(uri => URI->new($url), redirect => $redirect));
    	return;
    }

    if (! $r->is_success) {
        Plagger->context->log(error => "Fetch for $url failed: " . $r->code);
        return;
    }

    # P::P::A::Simple does this bit as the first thing when aggregate()
    # gets called. But since we're going through Xango, we need to figure
    # out if this is the "original" feed or not

    if (! $job->notes('is_original_request')) {
        $plugin->handle_feed($url, $r->content_ref);
    } else {
        # If this is the original request, chack if the content we've
        # just fetched is a parsable feed. if not, refetch what's claimed
        # to be the feed.

        # XXX - Hack. P::F->discover likes to have URI::Fetch::Response
        my $ufr = TO_URI_FETCH_RESPONSE( $r );
        my $feed_url = Plagger::FeedParser->discover($ufr);
        if ($feed_url eq $url) {
            $plugin->handle_feed($url, $r->content_ref);
        } elsif($feed_url) {
            # OMG we should alias Feed so it can be looked up with $feed_url, too
            $plugin->{_url2feed}->{$feed_url} = $plugin->{_url2feed}->{$url};

            $_[KERNEL]->post($_[HEAP]->{BROKER_ALIAS}, 'enqueue_job', Xango::Job->new(uri => URI->new($feed_url), redirect => $redirect));
        }
    }

    if ($_[HEAP]->{USE_CACHE}) {
        $plugin->cache->set(
            $job->uri,
            {ETag => $r->header('ETag'),
                LastModified => $r->header('Last-Modified')}
        );
    }
}

sub TO_URI_FETCH_RESPONSE
{
    my ($r) = @_;

    my $ufr = URI::Fetch::Response->new();
    $ufr->http_status($r->code);
    $ufr->http_response($r);
    $ufr->status(
        $r->previous && $r->previous->code == &HTTP::Status::RC_MOVED_PERMANENTLY ? &URI::Fetch::URI_MOVED_PERMANENTLY :
        $r->code == &HTTP::Status::RC_GONE ? &URI::Fetch::URI_GONE :
        $r->code == &HTTP::Status::RC_NOT_MODIFIED ? &URI::Fetch::URI_NOT_MODIFIED :
        &URI::Fetch::URI_OK
    );
    $ufr->etag($r->header('ETag'));
    $ufr->last_modified($r->header('Last-Modified'));
    $ufr->uri($r->request->uri);
    $ufr->content($r->content);
    $ufr->content_type($r->content_type);

    return $ufr;
}

1;

