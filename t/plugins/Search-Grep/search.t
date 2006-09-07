use strict;
use FindBin;
use File::Spec;
use File::Path;
use t::TestPlagger;

test_plugin_deps('Search::Grep');

our $dir = File::Spec->catfile($FindBin::Bin, 'grepdb');

plan 'no_plan';
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
  - module: Search::Grep
    config:
      dir: $main::dir
--- expected
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
  - module: Search::Grep
    config:
      dir: $main::dir
--- expected
Plagger->set_context($context);
ok -e $main::dir, 'index exists';

my $feed;
$context->run_hook('searcher.search', { query => "murakami" }, 0, sub { $feed = $_[0] });
ok $feed, 'I still got feed';
is $feed->count, 1, 'murakami matches 1';

use Encode;
$context->run_hook('searcher.search', { query => decode_utf8("フォルダ") }, 0, sub { $feed = $_[0] });
ok $feed, 'I still got feed';
is $feed->count, 1, 'Unicode search';


