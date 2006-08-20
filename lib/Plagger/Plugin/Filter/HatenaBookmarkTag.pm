package Plagger::Plugin::Filter::HatenaBookmarkTag;
use strict;
use base qw( Plagger::Plugin );

use Plagger::UserAgent;
use URI;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'update.entry.fixup' => \&update,
    );
}

sub update {
    my($self, $context, $args) = @_;

    # xxx need cache & interval
    my $agent = Plagger::UserAgent->new;
    my $url  = 'http://b.hatena.ne.jp/entry/rss/' . $args->{entry}->permalink;
    my $feed = eval { $agent->fetch_parse( URI->new($url) ) };

    if ($@) {
        $context->log(error => "Feed error $url: $@");
        return;
    }

    for my $entry ($feed->entries) {
        my $tag = $entry->category or next;
           $tag = [ $tag ] unless ref($tag);

        for my $t (@{$tag}) {
            $args->{entry}->add_tag($t);
        }
    }
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::HatenaBookmarkTag - Fetch tags from Hatena Bookmark

=head1 SYNOPSIS

  - module: Filter::HatenaBookmarkTag

=head1 DESCRIPTION

B<Note: this module is mostly untested and written just for a proof of
concept. If you run this on your box with real feeds, Hatena might
throttle your IP. See http://b.hatena.ne.jp/ for details.>

This plugin queries Hatena Bookmark (L<http://b.hatena.ne.jp/>) using
its RSS feeds API to get the tags people added to the entries.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<Plagger::Plugin::Filter::HatenaBookmarkUsersCount>,
L<http://b.hatena.ne.jp/>

=cut
