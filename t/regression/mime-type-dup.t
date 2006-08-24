use strict;
use Test::More tests => 5;

use Plagger::Util;

my $warning;
$SIG{__WARN__} = sub { $warning .= "@_" };

is Plagger::Util::mime_type_of("flv"), "video/x-flv";
is Plagger::Util::mime_type_of("m4a"), "audio/aac";
is Plagger::Util::mime_type_of("foo.mp4"), "video/mp4";
is Plagger::Util::mime_type_of("bar.m4v"), "video/mp4";

is $warning, undef;
