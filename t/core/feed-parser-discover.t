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
http://d.hatena.ne.jp/miyagawa/rss
--- expected
http://d.hatena.ne.jp/miyagawa/rss

=== Straight Feed URL RSS2
--- input
http://d.hatena.ne.jp/miyagawa/rss2
--- expected
http://d.hatena.ne.jp/miyagawa/rss2

=== Auto-Disocvery
--- input
http://d.hatena.ne.jp/miyagawa/
--- expected
http://d.hatena.ne.jp/miyagawa/rss

=== No RSS Auto-Discovery
--- input
http://www.asahi.com
--- expected eval
undef
