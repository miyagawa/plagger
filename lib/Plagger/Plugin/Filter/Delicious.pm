package Plagger::Plugin::Filter::Delicious;
use strict;
use base qw( Plagger::Plugin );

use Digest::MD5 qw(md5_hex);
use URI;
use XML::Feed;

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
    sleep 1;
    my $url  = 'http://del.icio.us/rss/url/' . md5_hex($args->{entry}->permalink);
    my $feed = XML::Feed->parse( URI->new($url) );

    unless ($feed) {
        $context->log(warn => "Feed error $url: " . XML::Feed->errstr);
        return;
    }

    for my $entry ($feed->entries) {
        my @tag = split / /, ($entry->category || '');
           @tag or next;

        for my $tag (@tag) {
            $args->{entry}->add_tag($tag);
        }
    }

    $args->{entry}->meta->{delicious_users} = $feed->entries;
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::Delicious - Fetch tags and users count from del.icio.us

=head1 SYNOPSIS

  - module: Filter::Delicious

=head1 DESCRIPTION

B<Note: this module is mostly untested and written just for a proof of
concept. If you run this on your box with real feeds, del.icio.us wlil
be likely to ban your IP. See http://del.icio.us/help/ for details.>

This plugin queries del.icio.us using its RSS feeds API to get the
tags people added to the entries, and how many people bookmarked them.

Users count is stored in C<delicious_users> metadata of
Plagger::Entry, so that other plugins and smartfeeds can make use of.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<http://del.icio.us/help/>

=cut
