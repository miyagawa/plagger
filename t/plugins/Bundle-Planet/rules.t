use strict;
use FindBin;
use File::Path;
use t::TestPlagger;

test_plugin_deps;
plan 'no_plan';

our $dir    = "$FindBin::Bin/planet";
our $output = "$dir/index.html";

run_eval_expected;

END {
    rmtree $dir if $dir && -e $dir;
}

__END__

=== Test rules
--- input config output_file
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/rss-full.xml
  - module: Bundle::Planet
    config:
      dir: $main::dir
      title: Planet Foobar
      url: http://planet.plagger.org/
      theme: sixapart-std
      stylesheet: foo.css
      duration: 3 years
      extra_rule:
        - expression: \$args->{entry}->link =~ /20060710/
--- expected
like $block->input, qr!<a href="http://d.hatena.ne.jp/higepon/20060709!;
unlike $block->input, qr/Lazyweb/
