use strict;
use FindBin;
use File::Spec;
use File::Path;
use t::TestPlagger;

test_requires('KinoSearch');

our $dir = File::Spec->catfile($FindBin::Bin, 'invindex');

plan tests => 8;
run_eval_expected;

END {
    rmtree $dir if $dir && -e $dir;
}

__END__

=== Search
--- input config
global:
  log:
    level: error
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file:///$FindBin::Bin/../../samples/vox.xml
  - module: Search::KinoSearch
    config:
      invindex: $main::dir
--- expected
ok -e $main::dir, 'invindex exists';

# xxx this is clumsy
no warnings 'redefine';
*Plagger::context = sub { $context };

my $feed;
$context->run_hook('searcher.search', { query => "murakami" }, 0, sub { $feed = $_[0] });
ok $feed, 'I got feed';
is $feed->count, 1, 'murakami matches 1';

$context->run_hook('searcher.search', { query => "foobar" }, 0, sub { $feed = $_[0] });
ok $feed, 'I still got feed';
is $feed->count, 0, 'No match';

=== Second run ... make sure it's not clobbered
--- input config
global:
  log:
    level: error
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file:///$FindBin::Bin/../../samples/rss-full.xml
  - module: Search::KinoSearch
    config:
      invindex: $main::dir
--- expected
ok -e $main::dir, 'invindex exists';

# xxx this is clumsy
no warnings 'redefine';
*Plagger::context = sub { $context };

my $feed;
$context->run_hook('searcher.search', { query => "murakami" }, 0, sub { $feed = $_[0] });
ok $feed, 'I still got feed';
is $feed->count, 1, 'murakami matches 1';

