use strict;
use FindBin;
use File::Path qw(rmtree);

BEGIN {
    use t::TestPlagger;
    test_plugin_deps('Publish-Gmail');
    test_requires('MIME::Parser');
    test_requires_network;
}

plan tests => 2;

our $tmpdir = "$FindBin::Bin/tmp";

my $entity;

no warnings 'redefine';
local *MIME::Lite::send = sub {
    my($mime, @args) = @_;

    my $parser = MIME::Parser->new;
    $parser->output_to_core(1);
    $entity = $parser->parse_data($mime->as_string);
};

sub entity { $entity }

run_eval_expected;

END { rmtree $tmpdir if $tmpdir }

__END__

=== test via Gmail sender
--- input config entity
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
         link: http://bulknews.typepad.com/
         body: |
           Hello <img src="http://bulknews.typepad.com/P506iC0003735833.jpg" /> foobar

  - module: Filter::FindEnclosures
  - module: Filter::FetchEnclosure
    config:
      dir: $main::tmpdir

  - module: Publish::Gmail
    config:
      mailto: foobar@localhost
      attach_enclosures: 1
--- expected
my $entity = $block->input;
ok $entity->parts(0)->bodyhandle->as_string =~ m!<img src="cid:(.*?)" />!;
is $entity->parts(1)->head->get('Content-Id'), "<$1>\n";
