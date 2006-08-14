use strict;
use t::TestPlagger;

plan tests => 1;
run_eval_expected;

__END__

=== RSS category
--- input config
global:
  log:
    level: error
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/rss2sample.xml
--- expected
is $context->update->feeds->[0]->entries->[0]->tags->[0], 'News';

