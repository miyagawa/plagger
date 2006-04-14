package Plagger::Plugin::Subscription::2chThreadList;
use strict;
use base qw( Plagger::Plugin );

use URI;
use XML::Feed;

sub register {
    my($self, $context) = @_;

    $context->register_hook(
        $self,
        'subscription.load' => \&load,
    );
}

sub load {
    my($self, $context) = @_;

    my $threadlist_uri = $self->conf->{url}
        or $context->error('ThreadList url is missing');

    my $remote = XML::Feed->parse(URI->new($threadlist_uri)) or $context->error("feed parse error $threadlist_uri");
    for my $r ($remote->entries) {
        $context->log(info => "thread: ". $r->link);

        my $feed = Plagger::Feed->new;
        $feed->url($r->link);
        $feed->link($r->link);
        $feed->title($r->title);
        $context->subscription->add($feed);
    }
}

1;
