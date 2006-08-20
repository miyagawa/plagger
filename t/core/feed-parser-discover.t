use t::TestPlagger;

use Plagger::FeedParser;
use Plagger::UserAgent;

test_requires_network;
plan tests => 1 * blocks;

filters { input => 'chomp', expected => 'chomp' };

run {
    my $block = shift;
    my $ua  = Plagger::UserAgent->new;
    my $res = $ua->fetch($block->input);
    my $url = Plagger::FeedParser->discover($res);
    is $url, $block->expected, $block->name;
}

__END__

=== Straight Feed URL
--- input
http://feeds.feedburner.com/bulknews
--- expected
http://feeds.feedburner.com/bulknews

=== Straight Feed TypePad
--- input
http://bulknews.typepad.com/blog/atom.xml
--- expected
http://bulknews.typepad.com/blog/atom.xml

=== Auto-Disocvery
--- input
http://subtech.g.hatena.ne.jp/miyagawa/
--- expected
http://subtech.g.hatena.ne.jp/miyagawa/rss2

=== No RSS Auto-Discovery
--- input
http://www.asahi.com
--- expected eval
undef
