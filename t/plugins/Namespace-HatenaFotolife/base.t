use strict;
use FindBin;

use t::TestPlagger;

plan tests => 3;
run_eval_expected;

__END__

=== Hatena Fotolife
--- input config
global:
  log:
    level: error
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/hatenafotolife.rdf

--- expected
my @feeds = $context->update->feeds;
is( ($feeds[0]->entries)[0]->enclosures->[0]->url, 'http://f.hatena.ne.jp/images/fotolife/m/miyagawa/20060529/20060529191228.gif' );
is( ($feeds[0]->entries)[0]->enclosures->[0]->type, 'image/gif' );
is( ($feeds[0]->entries)[0]->icon->{url}, 'http://f.hatena.ne.jp/images/fotolife/m/miyagawa/20060529/20060529191228_m.jpg' );

