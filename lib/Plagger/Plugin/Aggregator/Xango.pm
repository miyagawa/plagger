# $Id$
#
# Copyright (c) 2006 Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

package Plagger::Plugin::Aggregator::Xango;
use strict;
use base qw( Plagger::Plugin::Aggregator::Simple );
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
        Plugin => $self,
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
        heap => { PLUGIN => $args{Plugin} },
        package_states => [
            $class => [ qw(_start _stop apply_policy handle_response) ]
        ]
    );
}

sub _start { $_[KERNEL]->alias_set('xghandler') }
sub _stop  { }
sub handle_response {
    my $job = $_[ARG0];
    my $plugin = $_[HEAP]->{PLUGIN};

    my $r = $job->notes('http_response');
    my $url    = $job->uri;

    $plugin->handle_feed($url, $r->content_ref);
}

1;

