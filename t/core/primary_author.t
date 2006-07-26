use strict;
use t::TestPlagger;

use Plagger::Feed;

plan tests => 1 * blocks;

run {
    my $block = shift;
    my $feed  = Plagger::Feed->new;

    for my $author ($block->input) {
        my $entry = Plagger::Entry->new;
        $entry->title("foo");
        $entry->author($author);
        $feed->add_entry($entry);
    }

    is $feed->primary_author, $block->expected;
};

__END__

=== same authors
--- input lines chomp
miyagawa
miyagawa

--- expected chomp
miyagawa

=== different authors
--- input lines chomp
miyagawa
foobar

--- expected eval
undef

=== same authors with empty one
--- input eval
"miyagawa", undef, "miyagawa"

--- expected chomp
miyagawa
