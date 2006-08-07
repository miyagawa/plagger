use strict;
use FindBin;
use File::Path;
use t::TestPlagger;

test_requires_network;
test_plugin_deps;

unless (-e "$ENV{HOME}/svn/feedvalidator") {
    plan skip_all => "You need to checkout feedvalidator in $ENV{HOME}/svn to run this test";
}

plan 'no_plan';

our $dir    = "$FindBin::Bin/planet";
our $output = "$dir/atom.xml";

run_eval_expected;

END {
    rmtree $dir if $dir && -e $dir;
}

__END__

=== Test Atom 1.0 feed validity
--- input config
global:
  log:
    level: error
  assets_path: $FindBin::Bin/../../../assets
plugins:
  - module: Subscription::Config
    config:
      feed:
        - http://blog.bulknews.net/mt/index.rdf
        - http://subtech.g.hatena.ne.jp/miyagawa/rss
  - module: Bundle::Planet
    config:
      dir: $main::dir
      title: Planet Foobar
      url: http://planet.plagger.org/
      theme: sixapart-std
      stylesheet: foo.css
--- expected
my $out = `$ENV{HOME}/svn/feedvalidator/src/demo.py $main::output A`;
like $out, qr/No errors or warnings/;
