use strict;
use t::TestPlagger;

plan tests => 1 * blocks;

filters { input => 'chomp' };

run {
    my $block = shift;
    my $entry = Plagger::Entry->new;
    $entry->id($block->input);
    like $entry->id_safe, qr/^[\w\-]+$/, $block->input;
}

__END__

===
--- input
http://www.google.com/

===
--- input
https://www.google.com/

===
--- input
tag:un-q.net,2006://1.4

===
--- input
urn:guid:BB054AF0-2601-11DB-9738-946FBD312859
