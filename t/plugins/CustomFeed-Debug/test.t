use strict;
use t::TestPlagger;

plan 'no_plan';

run_eval_expected;

__END__

=== Test Debug
--- input config
plugins:
  - module: CustomFeed::Debug
    config:
      title: 'My Feed'
      link: 'http://localhost/'
      entry:
        - title: 'First Entry'
          link: 'http://localhost/1'
          body: 'Hello World! :)'
        - title: 'Second Entry'
          link: 'http://localhost/2'
          body: 'Good Bye! :P'

--- expected
is $context->update->feeds->[0]->link, 'http://localhost/';
is $context->update->feeds->[0]->title, 'My Feed';
ok $context->update->feeds->[0]->count;
ok $context->update->feeds->[0]->entries->[0]->title;
ok $context->update->feeds->[0]->entries->[0]->link;
ok $context->update->feeds->[0]->entries->[0]->body;
ok $context->update->feeds->[0]->entries->[1]->title;
ok $context->update->feeds->[0]->entries->[1]->link;
ok $context->update->feeds->[0]->entries->[1]->body;
