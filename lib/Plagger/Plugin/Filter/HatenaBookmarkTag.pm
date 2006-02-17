package Plagger::Plugin::Filter::HatenaBookmarkTag;
use strict;
use base qw( Plagger::Plugin );

use URI;
use XML::Feed;

$XML::Feed::RSS::PREFERRED_PARSER = 'XML::RSS::LibXML';

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
    my $url  = 'http://b.hatena.ne.jp/entry/rss/' . $entry->permalink;
    my $feed = XML::Feed->parse( URI->new($url) );

    unless ($feed) {
        $context->log(warn => "Feed error $url: " . XML::Feed->errstr);
        return;
    }

    for my $entry ($feed->entries) {
        my $tag = $entry->category or next;
        $tag = [ $tag ] unless ref($tag);

        for my $t (@{$tag}) {
            $entry->add_tag($t);
        }
    }
}

1;
