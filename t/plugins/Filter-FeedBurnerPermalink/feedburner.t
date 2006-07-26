use strict;
use t::TestPlagger;

test_requires_network;
plan 'no_plan';

my $log;
$SIG{__WARN__} = sub { $log .= "@_" };
sub log { $log }

run_eval_expected;

__END__

=== sixapart.com feed
--- input config log
global:
  log:
#    level: error
plugins:
  - module: Subscription::Config
    config:
      feed:
        - http://www.sixapart.com/pronet/weblog/

  - module: Filter::FeedBurnerPermalink
--- expected
my $log = $block->input;
like $log, qr/Permalink rewritten to/;
