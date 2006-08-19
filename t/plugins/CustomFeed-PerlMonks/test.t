use strict;
use t::TestPlagger;

test_requires_network 'perlmonks.org:80';

plan 'no_plan';

run_eval_expected;

__END__

=== Test PerlMonks CustomFeed
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - http://perlmonks.org/?node_id=30175

  - module: CustomFeed::PerlMonks

--- expected
is $context->update->feeds->[0]->link, 'http://perlmonks.org/?node_id=30175';
ok $context->update->feeds->[0]->count;
ok $context->update->feeds->[0]->entries->[0]->title;
ok $context->update->feeds->[0]->entries->[0]->link;
ok $context->update->feeds->[0]->entries->[0]->author;
