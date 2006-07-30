use strict;
use FindBin;
use File::Spec;
use File::Path;
use IO::Socket::INET;
use List::Util qw(first);
use LWP::UserAgent;

use t::TestPlagger;

test_requires('Search::Estraier');
test_requires('Tie::File');
test_requires_command('estmaster');

our $dir = File::Spec->catfile($FindBin::Bin, 'estdb');
our $port;

eval { init_estmaster($dir) };
if ($@) {
    plan skip_all => $@;
}

plan 'no_plan';
run_eval_expected;

sub init_estmaster {
    my($dir) = @_;

    # find random open port
    $port = first { !IO::Socket::INET->new("localhost:$_") }
            map { 1000 + int rand(10000) } 1..10;

    diag("Use port $port for testing");

    # init estdb
    system('estmaster', 'init', $dir);

    # inline edit via Tie::File
    tie my @conf, 'Tie::File', File::Spec->catfile($dir, '_conf') or die "_conf: $!";
    $conf[1] =~ s/portnum: .*/portnum: $port/
        or die "line 2 doesn't match with /portnum:/ $conf[1]";
    untie @conf;

    # start estmaster in background
    system('estmaster', 'start', '-bg', $dir);

    # sleep for a little bit for estmaster to startup
    sleep 1;

    # send HTTP POST to create a new node
    my $ua = LWP::UserAgent->new;
    $ua->credentials("localhost:$port", 'Super User', 'admin', 'admin');
    my $res = $ua->post("http://localhost:$port/master_ui", [
        name => 'plagger',
        label => 'plagger',
        action => 8,
    ]);

    $res->content =~ /successfully/
        or die "Node creation failed: " . $res->content;
}

END {
    if ($dir && -e $dir) {
        my $pidfile = File::Spec->catfile($dir, '_pid');
        open my $fh, $pidfile or die "$pidfile: $!";
        chomp(my $pid = <$fh>);
        if ($pid) {
            diag("shutting down estmaster <pid:$pid>");
            kill 1, $pid;
        }
        rmtree $dir;
    }
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
  - module: Search::Estraier
    config:
      url: http://localhost:$main::port/node/plagger
--- expected
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
  - module: Search::Estraier
    config:
      url: http://localhost:$main::port/node/plagger
--- expected
ok -e $main::dir, 'invindex exists';

# xxx this is clumsy
no warnings 'redefine';
*Plagger::context = sub { $context };

my $feed;
$context->run_hook('searcher.search', { query => "murakami" }, 0, sub { $feed = $_[0] });
ok $feed, 'I still got feed';
is $feed->count, 1, 'murakami matches 1';

use Encode;
$context->run_hook('searcher.search', { query => decode_utf8("フォルダ") }, 0, sub { $feed = $_[0] });
ok $feed, 'I still got feed';
is $feed->count, 1, 'Unicode search';


