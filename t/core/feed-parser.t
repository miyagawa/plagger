use utf8;
use t::TestPlagger;
use Plagger::UserAgent;

test_requires_network;
plan tests => 1 * blocks;

filters { input => 'chomp', expected => 'chomp' };

run {
    my $block = shift;
    my $ua   = Plagger::UserAgent->new;
    my $feed = $ua->find_parse($block->input);
    is $feed->title, $block->expected, $block->name;
}

__END__

=== Straight Feed URL
--- input
http://d.hatena.ne.jp/miyagawa/rss
--- expected
miyagawaの日記

=== Straight Feed URL RSS2
--- input
http://d.hatena.ne.jp/miyagawa/rss2
--- expected
miyagawaの日記

=== Auto-Discovery
--- input
http://d.hatena.ne.jp/miyagawa/
--- expected
miyagawaの日記
