package Plagger::Plugin::Subscription::Config;
use strict;
use base qw( Plagger::Plugin );

sub register {
    my($self, $context) = @_;

    $context->register_hook(
        $self,
        'subscription.load' => \&load,
    );
}

sub load {
    my($self, $context) = @_;

    my $feeds = $self->conf->{feed};
       $feeds = [ $feeds ] unless ref $feeds;

    for my $config (@$feeds) {
        my $feed = Plagger::Feed->new;
        $feed->url($config->{url}) or $context->error("Feed URL is missing");
        $feed->link($config->{link})   if $config->{link};
        $feed->title($config->{title}) if $config->{title};

        if ($config->{tags}) {
            require Text::Tags::Parser;
            my @tags = Text::Tags::Parser->new->parse_tags($config->{tags});
            $feed->tags(\@tags);
        }

        $context->subscription->add($feed);
    }
}

1;
