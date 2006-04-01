package Plagger::Plugin::Subscription::Config;
use strict;
use base qw( Plagger::Plugin );

use Plagger::Tag;

sub register {
    my($self, $context) = @_;

    $context->register_hook(
        $self,
        'subscription.load' => $self->can('load'),
    );
}

sub load {
    my($self, $context) = @_;

    my $feeds = $self->conf->{feed};
       $feeds = [ $feeds ] unless ref $feeds;

    for my $config (@$feeds) {
        if (!ref($config)) {
            $config = { url => $config };
        }
        my $feed = Plagger::Feed->new;
        $feed->url($config->{url}) or $context->error("Feed URL is missing");
        $feed->link($config->{link})   if $config->{link};
        $feed->title($config->{title}) if $config->{title};
        $feed->meta($config->{meta})   if $config->{meta};

        if (my $tags = $config->{tag}) {
            unless (ref $tags) {
                $tags = [ Plagger::Tag->parse($config->{tag}) ];
            }
            $feed->tags($tags);
        }

        $context->subscription->add($feed);
    }
}

1;

__END__

=head1 NAME

Plagger::Plugin::Subscription::Config - Subscription in config.yaml

=head1 SYNOPSIS

    - module: Subscription::Config
      config:
        feed:
          - url: http://bulknews.typepad.com/blog/atom.xml
          - url: http://blog.bulknews.net/mt/index.rdf

=head1 DESCRIPTION

This plugin allows you to configure your subscription I<hardwired> in
C<config.yaml>.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>

=cut
