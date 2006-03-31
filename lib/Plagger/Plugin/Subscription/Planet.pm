package Plagger::Plugin::Subscription::Planet;
use strict;
use base qw( Plagger::Plugin::Subscription::Config );

sub load {
    my($self, $context) = @_;

    map {
        s/%s/$self->conf->{keyword}/eg;
        push @{$self->conf->{feed}}, { url => $_ }
    } @{[
        'http://blogsearch.google.com/blogsearch_feeds?hl=en&q=%s&btnG=Search+Blogs',
        'http://blog.goo.ne.jp/search/search.php?status=select&tg=all&st=time&dc=10&dp=all&bu=&ts=all&MT=%s&da=all&rss=1',
        'http://www.namaan.net/rss?namaan=NAMA&ty=5&query=%s',
        # 'http://www.jetrun.jp/index.rdf?keyword=%s&si=0&upspan=0&area=&capage=1&pod=0&siteurl=',
        'http://search.msn.co.jp/results.aspx?q=%s&format=rss&FORM=RSRE',
        'http://bulkfeeds.net/app/search2.rdf?q=%s',
#        'http://www.feedster.com/search/type/rss/%s',
        'http://rss.sf.livedoor.com/search?q=%s&sf=update_date&start=0',
        'http://rss.rdy.jp/y2rss.cgi?query=%s&enc=UTF-8',
        'http://b.hatena.ne.jp/t/%s?mode=rss&sort=eid&threshold=1',
        'http://d.hatena.ne.jp/keyworddiary/%s?mode=rss',
    ]};

    $self->SUPER::load($context);
}

1;
