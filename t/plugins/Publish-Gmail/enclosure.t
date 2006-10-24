use strict;
use File::Path qw(rmtree);

BEGIN {
    use t::TestPlagger;
    test_plugin_deps('Filter-FetchEnclosure');
    test_plugin_deps('Filter-FindEnclosures');
    test_plugin_deps;
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

run_eval_expected_with_capture;

END { rmtree $tmpdir if $tmpdir }

__END__

=== Error enclosure URL
--- input config entity
global:
  log:
    level: debug
plugins:
  - module: CustomFeed::Debug
    config:
      title: Test
      link: http://example.com/
      entry:
       - title: Test 1
         link: http://bulknews.typepad.com/
         body: |
           Hello <a href="/../example.mp3">Goo</a>

  - module: Filter::FindEnclosures
  - module: Filter::FetchEnclosure
    config:
      dir: $main::tmpdir

  - module: Publish::Gmail
    config:
      mailto: foobar@localhost
      attach_enclosures: 1
--- expected
unlike $warnings, qr/Error while/;
like $warnings, qr/doesn't exist. Skip/;
