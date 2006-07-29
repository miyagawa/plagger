use strict;
use FindBin;
use t::TestPlagger;

plan 'no_plan';
run_eval_expected;

__END__

=== Feed extracted title
--- input config
global:
  log:
    level: error
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file:///$FindBin::Bin/../samples/rss-full.xml
--- expected
is $context->subscription->feeds->[0]->title, "Bulknews::Subtech";

=== Feed title in config
--- input config
global:
  log:
    level: error
plugins:
  - module: Subscription::Config
    config:
      feed:
        - url: file:///$FindBin::Bin/../samples/rss-full.xml
          title: Foo
--- expected
is $context->subscription->feeds->[0]->title, "Foo";
