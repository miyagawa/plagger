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

    my $map = XMLRPC::Lite
        -> proxy('http://b.hatena.ne.jp/xmlrpc')
        -> call('bookmark.getCount', @permalink)
        -> result;

    unless ($map) {
        $context->log(warn => 'Hatena Bookmark XMLRPC failed');
        return;
    }

    for my $entry ($args->{feed}->entries) {
        if (defined(my $count = $map->{$entry->permalink})) {
            $entry->meta->{hatenabookmark_users} = $count;
        }
    }
}

1;
