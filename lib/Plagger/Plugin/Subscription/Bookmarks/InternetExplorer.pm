package Plagger::Plugin::Subscription::Bookmarks::InternetExplorer;
use base qw( Plagger::Plugin::Subscription::Bookmarks );

use Encode;
use File::Basename qw( basename );
use Win32::IEFavorites;
use Win32::Locale;

use URI;

sub load {
    my($self, $context) = @_;

    my @items = Win32::IEFavorites->find(); # TODO: support expression?
    for my $item (@items) {
        my $url = URI->new( $item->url );
        next if $url->scheme !~ /^http/;

        my $language = Win32::Locale::get_language();
        my $fs_encoding = $lanuage eq 'ja' ? "cp932" : "latin-1"; # xxx utf-8?

        my $title = basename($item->path);
        $title =~ s/\.url$//;
        $title = decode($fs_encoding, $title);
        
        my $feed = Plagger::Feed->new;
        $feed->url($item->url);
        $feed->title($title);
        # TODO: add favico?
        # TODO: tag support by folder name
        
        $context->subscription->add($feed);
    }
}

1;