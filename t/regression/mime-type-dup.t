use strict;
use Test::More tests => 3;

use Plagger::Util;

my $warning;
$SIG{__WARN__} = sub { $warning .= "@_" };

is Plagger::Util::mime_type_of("flv"), "video/flv";
is Plagger::Util::mime_type_of("m4a"), "audio/aac";

is $warning, undef;
