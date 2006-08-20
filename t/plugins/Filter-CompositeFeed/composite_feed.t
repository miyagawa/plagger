use strict;
use t::TestPlagger;

plan 'no_plan';

run_eval_expected;

__END__

=== Test Filter::CompositeFeed
--- input config
plugins:
  - module: CustomFeed::Debug
    config:
      title: 'Feed 0'
      link: 'http://mizzy.org/plagger-test/0'
      description: 'Description of Feed 0'
      entry:
        - title: 'Entry of Feed 0'
          body: 'Entry of Feed 0'

  - module: CustomFeed::Debug
    config:
      title: 'Feed 1'
      link: 'http://mizzy.org/plagger-test/1'
      description: 'Description of Feed 1'
      entry:
        - title: 'Entry of Feed 1'
          body: 'Entry of Feed 1'

  - module: Filter::CompositeFeed

--- expected
is $context->update->feeds->[0]->title, 'All feeds';
is $context->update->feeds->[1], undef;
is $context->update->feeds->[0]->entries->[0]->title, 'Feed 0';
is $context->update->feeds->[0]->entries->[0]->link, 'http://mizzy.org/plagger-test/0';
is $context->update->feeds->[0]->entries->[0]->body, 'Description of Feed 0';
is $context->update->feeds->[0]->entries->[1]->title, 'Feed 1';
is $context->update->feeds->[0]->entries->[1]->link, 'http://mizzy.org/plagger-test/1';
is $context->update->feeds->[0]->entries->[1]->body, 'Description of Feed 1';
