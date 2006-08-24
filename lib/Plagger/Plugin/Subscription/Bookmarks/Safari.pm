package Plagger::Plugin::Subscription::Bookmarks::Safari;
use strict;
use base qw( Plagger::Plugin::Subscription::Bookmarks );

use Mac::Tie::PList;
use URI;

sub load {
    my($self, $context) = @_;

    my $plist = Mac::Tie::PList->new_from_file($self->conf->{path});
    $self->find_feed($context, $plist);
}

sub find_feed {
    my($self, $context, $plist, @tags) = @_;

    if($plist->{Children}) {
	push(@tags, $plist->{Title}) if $plist->{Title};

	for my $child (@{$plist->{Children}}) {
	    $self->find_feed($context, $child, @tags);
	}
    } elsif($plist->{URLString}) {
	my $url = new URI($plist->{URLString});

	if($url->scheme eq 'feed') {
	    if($url->as_string =~ m|^feed:https|) {
		$url->scheme('');
	    } else {
		$url->scheme('http');
	    }
	}

	my $feed = Plagger::Feed->new;
	$feed->url($url->as_string);
	$feed->title($plist->{URIDictionary}->{title});
	$feed->tags(\@tags);
	$context->subscription->add($feed);
    }
}
    
1;
