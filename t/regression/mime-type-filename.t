use strict;
use t::TestPlagger;
use Plagger::Util;

plan tests => 2;

sub mime {
    Plagger::Util::mime_type_of(URI->new($_[0]))->type;
}

filters { input => 'mime', expected => 'chomp' };
run_is 'input' => 'expected';

__END__

=== mp3
--- input
http://localhost/foo.mp3
--- expected
audio/mpeg

=== filename with dot
--- input
http://localhost/foo.bar.mp3
--- expected
audio/mpeg
