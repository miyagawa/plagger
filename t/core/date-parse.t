use strict;
use t::TestPlagger;

use Plagger::Date;

filters { input => 'chomp', expected => 'chomp' };
plan tests => 1 * blocks;

run {
    my $block = shift;
    my $dt = Plagger::Date->parse_dwim($block->input);
    is $dt->format('W3CDTF'), $block->expected;
}

__END__

=== Floating
--- input
2006/10/14 12:55:00
--- expected
2006-10-14T12:55:00

=== JST
--- input
2006/10/14 12:55:00 JST
--- expected
2006-10-14T12:55:00+09:00

=== PDT
--- input
2006/10/14 12:55:00 PDT
--- expected
2006-10-14T12:55:00-07:00

=== UTC
--- input
2006/10/14 12:55:00 UTC
--- expected
2006-10-14T12:55:00Z
