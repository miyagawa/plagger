package Plagger::Plugin::Subscription::HatenaGroup;
use strict;
use base qw( Plagger::Plugin );

use URI;
use Plagger::FeedParser;
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

    my $group = $self->conf->{group}
        or $context->error('group is missing');

    my $feed_uri = "http://$group.g.hatena.ne.jp/diarylist?mode=rss";

    my $agent = Plagger::UserAgent->new;
    my $remote = eval { $agent->fetch_parse(URI->new($feed_uri)) }
        or $context->error("feed parse error $feed_uri: $@");
    for my $r ($remote->entries) {
        $context->log(info => "diary: ". $r->link);

        my $feed = Plagger::Feed->new;
        $feed->url($r->link . "rss");
        $feed->link($r->link);
        $feed->title($r->title);
        $context->subscription->add($feed);
    }
}

1;

__END__

=head1 NAME

Plagger::Plugin::Subscription::HatenaGroup - HatenaGroup Subscription via RSS

=head1 SYNOPSIS

  - module: Subscription::HatenaGroup
    config:
      group: subtech

=head1 DESCRIPTION

Subscription from Hatena Group.

=head1 AUTHOR

Tokuhiro Matsuno

=head1 SEE ALSO

L<Plagger>, L<XML::Feed>

=cut
