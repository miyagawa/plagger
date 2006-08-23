use strict;
use t::TestPlagger;

plan 'no_plan';
run_eval_expected;

__END__

=== RSS 2.0 with image
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/rss2-image.xml
--- expected
ok $context->update->feeds->[0]->entries->[1]->icon;


