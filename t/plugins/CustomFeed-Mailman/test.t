use strict;
use t::TestPlagger;

test_requires_network 'lists.rawmode.org:80';

plan 'no_plan';
run_eval_expected;

__END__

=== Test Simple CustomFeed
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - http://lists.rawmode.org/pipermail/catalyst/
 	
  - module: CustomFeed::Mailman

--- expected
is $context->update->feeds->[0]->link, 'http://lists.rawmode.org/pipermail/catalyst/';
ok $context->update->feeds->[0]->count;
ok $context->update->feeds->[0]->entries->[0]->title;
ok $context->update->feeds->[0]->entries->[0]->link;
