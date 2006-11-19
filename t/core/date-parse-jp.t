use strict;
use utf8;
use t::TestPlagger;
use Plagger::Date;

test_requires 'DateTime::Format::Japanese';

filters 'chomp';

plan tests => 1 * blocks;

run {
    my $block = shift;
    my $dt = Plagger::Date->parse_dwim($block->input);
    is $dt->format('W3CDTF'), $block->expected;
}

__END__

=== Floating
--- input
平成18年11月18日
--- expected
2006-11-18T00:00:00

