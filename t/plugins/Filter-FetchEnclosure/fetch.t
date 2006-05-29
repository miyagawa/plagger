use strict;
use FindBin;
use File::Path qw(rmtree);
use Test::More tests => 2;

use Plagger;
use MIME::Parser;
use MIME::Lite;

my $tmpdir = "$FindBin::Bin/tmp";

no warnings 'redefine';
local *MIME::Lite::send = sub {
    my($mime, @args) = @_;

    my $parser = MIME::Parser->new;
    $parser->output_to_core(1);
    my $entity = $parser->parse_data($mime->as_string);

    ok $entity->parts(0)->bodyhandle->as_string =~ m!<img src="cid:(.*?)" />!;
    is $entity->parts(1)->head->get('Content-Id'), "<$1>\n";
};

Plagger->bootstrap(config => \<<"CONFIG");
global:
  assets_path: $FindBin::Bin/../../../assets
  log:
    level: error
plugins:
  - module: CustomFeed::Debug
    config:
      title: Test
      link: http://example.com/
      entry:
       - title: Test 1
         body: |
           Hello <img src="http://bulknews.typepad.com/P506iC0003735833.jpg" /> foobar

  - module: Filter::FindEnclosures
  - module: Filter::FetchEnclosure
    config:
      dir: $tmpdir

  - module: Publish::Gmail
    config:
      mailto: fooba\@localhost
CONFIG

END { rmtree $tmpdir }
