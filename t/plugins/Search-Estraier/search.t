use strict;
use FindBin;
use File::Spec;
use File::Path;
use IO::Socket::INET;
use List::Util qw(first);
use LWP::UserAgent;

use t::TestPlagger;

test_plugin_deps;
test_requires('Tie::File');
test_requires_command('estmaster');

my $ver = `estconfig --version`;
if ($ver =~ /^1\.3/) {
    plan skip_all => "This test doesn't work with 1.3.x yet: $ver";
}

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
    my $done;
    for my $line (@conf) {
        $line =~ s/portnum: .*/portnum: $port/ and $done = 1;
    }
    untie @conf;

    unless ($done) {
        die "_conf file doesn't have portnum:";
    }

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
        diag("shutting down estmaster");
        system('estmaster', 'stop', $dir);
        rmtree $dir;
    }
}

__END__

=== Search
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/vox.xml
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
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/rss-full.xml
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


