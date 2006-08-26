use strict;
use t::TestPlagger;
use Plagger::Util;

plan tests => 1 * blocks;
filters { input => 'chomp', expected => 'chomp' };

run {
    my $block = shift;
    my $mime = Plagger::Util::mime_type_of(URI->new($block->input));
    my $val  = Plagger::Util::mime_is_enclosure($mime) ? 1 : 0;
    is $val, $block->expected, $block->input;
};

__END__

===
--- input
http://localhost/foo.mp3
--- expected
1

===
--- input
http://localhost/foo.mp4
--- expected
1

===
--- input
http://localhost/foo.jpg
--- expected
1

===
--- input
http://localhost/foo.jpeg
--- expected
1

===
--- input
http://localhost/foo.ogg
--- expected
1

===
--- input
http://localhost/foo.mp3?foo=1
--- expected
1

===
--- input
http://localhost/foo.bar.mp3
--- expected
1

===
--- input
http://localhost/foo.html
--- expected
0

===
--- input
http://localhost/foo.txt
--- expected
0
