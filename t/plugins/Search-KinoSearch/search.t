use strict;
use FindBin;
use File::Spec;
use File::Path;
use t::TestPlagger;

test_plugin_deps;

our $dir = File::Spec->catfile($FindBin::Bin, 'invindex');

plan tests => 8;
run_eval_expected;

END {
    rmtree $dir if $dir && -e $dir;
}

__END__

=== Search
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/vox.xml
  - module: Search::KinoSearch
    config:
      invindex: $main::dir
--- expected
ok -e $main::dir, 'invindex exists';
Plagger->set_context($context);

my $feed;
$context->run_hook('searcher.search', { query => "murakami" }, 0, sub { $feed = $_[0] });
ok $feed, 'I got feed';
is $feed->count, 1, 'murakami matches 1';

$context->run_hook('searcher.search', { query => "foobar" }, 0, sub { $feed = $_[0] });
ok $feed, 'I still got feed';
is $feed->count, 0, 'No match';

=== Second run ... make sure it's not clobbered
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/rss-full.xml
  - module: Search::KinoSearch
    config:
      invindex: $main::dir
--- expected
ok -e $main::dir, 'invindex exists';
Plagger->set_context($context);

my $feed;
$context->run_hook('searcher.search', { query => "murakami" }, 0, sub { $feed = $_[0] });
ok $feed, 'I still got feed';
is $feed->count, 1, 'murakami matches 1';

