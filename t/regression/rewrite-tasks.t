use strict;
use t::TestPlagger;
use File::Temp qw(tempfile);

plan tests => 1;

my($fh, $filename) = tempfile();

print $fh <<CONF;
plugins:
  - module: CustomFeed::Simple
    config:
      password: foo
CONF
close $fh;

Plagger->new(config => $filename);
file_contains($filename, qr/base64/);
