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
http://subtech.g.hatena.ne.jp/miyagawa/rss
--- expected
Bulknews::Subtech

=== Auto-Discovery
--- input
http://blog.bulknews.net/mt/
--- expected
blog.bulknews.net
