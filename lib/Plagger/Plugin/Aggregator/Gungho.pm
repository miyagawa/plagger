# $Id$
#
#
#

package Plagger::Plugin::Aggregator::Gungho::Handler;
use strict;
use base qw(Gungho::Handler::Null);

__PACKAGE__->mk_accessors($_) for qw(gungho_plugin);

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

sub handle_response
{
    my $self = shift;
    my $c    = shift;
    my $req  = shift;
    my $res  = shift;
    my $ufr  = TO_URI_FETCH_RESPONSE($res);

    $self->next::method($c, $req, $res);

    my $plugin   = $self->gungho_plugin;
    my $url      = $req->url;
    my $feed_url = Plagger::FeedParser->discover($ufr);
    if ($url eq $feed_url) {
        $plugin->handle_feed($url, \$ufr->content, $req->notes('feed'));
    } elsif ($feed_url) {
        my $clone = $req->clone;
        $clone->uri($feed_url);
        $plugin->gungho->send_request($clone);
    } else {
        return;
    }
}

package Plagger::Plugin::Aggregator::Gungho;
use strict;
use base qw(Plagger::Plugin::Aggregator::Simple);
use Gungho;
use Gungho::Request;

__PACKAGE__->mk_accessors($_) for qw(gungho requests);

sub register
{
    my ($self, $context) = @_;
    $context->register_hook(
        $self,
        'customfeed.handle'   => \&accumulate,
        'aggregator.finalize' => \&aggregate,
    );
    $self->requests([]);
}

sub accumulate
{
    my($self, $context, $args) = @_;
    
    my $url = $args->{feed}->url;
    return unless $url =~ m!^https?://!i;

    my $req = Gungho::Request->new(GET => $url);
    $req->notes( feed => $args->{feed} );
    $context->log(info => "Fetch $url");
    push @{ $self->requests }, $req;
}

sub aggregate
{
    my ($self, $context) = @_;
    my $g = Gungho->new({
        provider => {
            module => 'Simple'
        },
        handler  => {
            module => '+Plagger::Plugin::Aggregator::Gungho::Handler'
        }
    });

    $self->gungho($g);

    $g->provider()->requests( $self->requests );
    $g->provider()->has_requests( 1 );
    $self->requests([]);
    $g->handler()->gungho_plugin( $self );
    $g->run;
}

1;

__END__

=head1 NAME

Plagger::Plugin::Aggregator::Gungho - Go Gungho!

=head1 SYNOPSIS

  - module: Aggregator::Gungho

=head1 DESCRIPTION

[06 Apr 2007] Gungho is, as of this writing, extremely new crawler framework. 
Beware of bugs! Please report them to the author. I'll be happy to apply
patches or fix problems.

=head1 AUTHOR

Copyright (c) 2007 Daisuke Maki E<lt>daisuke@endeworks.jpE<gt>

=head1

