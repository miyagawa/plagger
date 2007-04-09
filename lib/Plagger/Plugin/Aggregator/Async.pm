package Plagger::Plugin::Aggregator::Async;
use strict;
use base qw( Plagger::Plugin::Aggregator::Simple );
use HTTP::Async 0.07;

__PACKAGE__->mk_accessors( qw/async/ );

sub register {
    my($self, $context) = @_;

    $self->async(
        HTTP::Async->new( %{$self->conf->{async_args} || {}} )
    );
    $self->{_id2feed} = {};

    $context->register_hook(
        $self,
        'customfeed.handle'   => \&aggregate,
        'aggregator.finalize' => \&finalize,
    );
}

sub aggregate {
    my($self, $context, $args) = @_;
    my $url = $args->{feed}->url;

    my $id = $self->async->add( $self->prep_req( $context, $url) );
    $self->{_id2feed}->{ $id } = $args->{feed};
}

sub prep_req {
    my ( $self, $context, $url ) = @_;
    my $req = HTTP::Request->new(
        GET => $url
    );
    $req->user_agent( "Plagger/$Plagger::VERSION (http://plagger.org/)" );
    
    my $ref = $self->cache->get($url);
    if ( $ref ) {
        $req->if_modified_since( $ref->{LastModified} ) 
            if $ref->{LastModified};
        $req->header('If-None-Match', $ref->{ETag} )
            if $ref->{ETag};
    }

    $req;
}

sub finalize {
    my($self, $context, $args) = @_;
    while ( my ( $response, $id ) = $self->async->wait_for_next_response ) {
        my $feed = $self->{_id2feed}->{$id};
        $context->log(info => "Fetch " . $feed->url);
        $self->handle_response( $context, $response, $feed );
    }
}

sub handle_response {
    my ( $self, $context, $response, $feed )  = @_;
    my $url = $response->request->uri;

    if ( $response->code == 304) {
        $context->log(error => "Not Modified: $url");
        return;
    }
    elsif (! $response->is_success) {
        $context->log(error => "Fetch for $url failed: " . $response->code);
        return;
    }

    my $ufr = TO_URI_FETCH_RESPONSE( $response );
    my $feed_url = Plagger::FeedParser->discover($ufr);
    if ($url eq $feed_url) {
        $self->handle_feed($url, \$response->content, $feed);
    } elsif ($feed_url) {
        my $new_id = $self->async->add( $self->prep_req($context, $feed_url ) );
        $self->{_id2feed}->{$new_id} = $feed;
    } else {
        return;
    }

    $self->cache->set(
        $response->request->uri,
        {
            ETag => $response->header('ETag') || '',
            LastModified => $response->header('Last-Modified') || ''
        }
    );

    return 1;
}


## XXX copy from Xango
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
__END__

=head1 NAME

Plagger::Plugin::Aggregator::Async -Aggregate with HTTP::Async

=head1 SYNOPSIS

  - module: Aggregator::Async
    conf:
      async_args:
        slots: 10
        max_redirect: 7

=head1 DESCRIPTION

This plugin implements paralle feed aggregation without blocking.

=head1 CONFIG

=over 4

=item async_args

=back

=head1 AUTHOR

Masahiro Nagano

=head1 SEE ALSO

L<Plagger>, L<Plagger::Aggregator::Simple>, L<HTTP::Async>

=cut
