package Plagger::Plugin::Subscription::2chThreadList;
use strict;
use base qw( Plagger::Plugin );

use URI;
use Plagger::UserAgent;

sub register {
    my($self, $context) = @_;

    $context->register_hook(
        $self,
        'subscription.load' => \&load,
    );
}

sub load {
    my($self, $context) = @_;

    my $threadlists = ref($self->conf->{url}) ? $self->conf->{url} : [ $self->conf->{url} ]
        or $context->error('ThreadList url is missing');

    my $agent = Plagger::UserAgent->new;

    for my $threadlist (@$threadlists) {
	my $remote = eval { $agent->fetch_parse($threadlist) }
            or $context->error("feed parse error: $@");
	for my $r ($remote->entries) {
	    $context->log(info => "thread: ". $r->link);

	    my $feed = Plagger::Feed->new;
	    $feed->url($r->link);
	    $feed->link($r->link);
	    $feed->title($r->title);
	    $context->subscription->add($feed);
	}
    }
}

1;
