package Plagger::Plugin::Filter::HatenaBookmarkUsersCount;
use strict;
use base qw( Plagger::Plugin );

use XMLRPC::Lite;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'update.feed.fixup' => \&update,
    );
}

sub update {
    my($self, $context, $args) = @_;

    my @permalink = map $_->permalink, $args->{feed}->entries;

    $context->log(info => 'Requesting XMLRPC call to Hatena Bookmark with ' . scalar(@permalink) . ' link(s)');

    my $map = XMLRPC::Lite
        ->proxy('http://b.hatena.ne.jp/xmlrpc')
        ->call('bookmark.getCount', @permalink)
        ->result;

    unless ($map) {
        $context->log(warn => 'Hatena Bookmark XMLRPC failed');
        return;
    }

    $context->log(info => 'XMLRPC request success.');

    for my $entry ($args->{feed}->entries) {
        if (defined(my $count = $map->{$entry->permalink})) {
            $entry->meta->{hatenabookmark_users} = $count;
        }
    }
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::HatenaBookmarkUsersCount - Queries Hatena Bookmark users count

=head1 SYNOPSIS

  - module: Filter::HatenaBookmarkUsersCount

=head1 DESCRIPTION

This plugin queries Hatena Bookmark (L<http://b.hatena.ne.jp/>) how
many people bookmarked each of feed entries, using its XMLRPC API
C<bookmark.getCount>.

Users count is stored in C<hatenabookmark_users> metadata of
Plagger::Entry so that other plugins or smartfeeds can make use of.

=head1 AUTHOR

Kazuhiro Osawa, Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plagger>, L<http://d.hatena.ne.jp/keyword/%A4%CF%A4%C6%A4%CA%A5%D6%A5%C3%A5%AF%A5%DE%A1%BC%A5%AF%B7%EF%BF%F4%BC%E8%C6%C0API>

=cut
