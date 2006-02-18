package Plagger::Plugin::Filter::Delicious;
use strict;
use base qw( Plagger::Plugin );

# NOTE this module is untested and written just for a proof of
# concept. If you run this on your box with real feeds, del.icio.us
# wlil be likely to ban your IP. See http://del.icio.us/help/ for
# details.

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
