package Plagger::Plugin::Widget::BloglinesSubscription;
use strict;
use base qw( Plagger::Plugin );

use HTML::Entities;
use URI;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'publish.entry.fixup' => \&add,
    );
}

sub add {
    my($self, $context, $args) = @_;

    my $feed = $args->{entry}->source || $args->{feed};
    unless (exists $feed->meta->{bloglines_subid}) {
        $context->log(warn => "bloglines_subid not found. Skip");
        return;
    }

    # create another Widget class to use feed info
    my $widget = Plagger::Plugin::Widget::BloglinesSubscription::Widget->new;
    $widget->{feed} = $feed;

    $args->{entry}->add_widget($widget);
}

package Plagger::Plugin::Widget::BloglinesSubscription::Widget;

sub new { bless {}, shift }

sub html {
    my($self, $entry) = @_;
    my $uri = URI->new('http://www.bloglines.com/modsub');

    $uri->query_form(subid => $self->{feed}->meta->{bloglines_subid});

    my $url = HTML::Entities::encode($uri->as_string);
    return qq(<a href="$url"><img src="http://www.bloglines.com/images/favicon.gif" alt="Edit Bloglines Subscription" style="border:0;vertical-align:middle" /></a>);
}

1;

__END__

=head1 NAME

Plagger::Plugin::Widget::BloglinesSubscription - Bloglines Subscription Widget

=head1 SYNOPSIS

  - module: Subscription::Bloglines
    config:
      fetch_meta: 1
      ...

  - module: Widget::BloglinesSubscription

=head1 DESCRIPTION

This plugins puts a widget to edit subscription on Bloglines. This
makes it easy for you to quickly unsubscribe to massively updated
feeds, or update feed configuration to ignore content updates.

You should use this plugin combined with
L<Plagger::Plugin::Subscription::Bloglines> and set I<fetch_meta>
config on.

=head1 TIPS

Due to how Bloglines works, the I<Unsubscribe> button on opened page
doesn't work (it requires window.opener to be a valid Bloglines
subscription page). Just append C<&remove=1> to the URL and you can
unsubscribe from the feed.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<Plagger::Plugin::Subscription::Bloglines>, L<http://www.bloglines.com/>

=cut
