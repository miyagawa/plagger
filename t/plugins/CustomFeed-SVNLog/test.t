use strict;
use t::TestPlagger;

test_requires_network 'svn.bulknews.net:80';
plan 'no_plan';

run_eval_expected;

__END__

=== Test SVNLog
--- input config
plugins:
    - module: CustomFeed::SVNLog
      config:
        target: http://svn.bulknews.net/repos/plagger/
        title: SVN Log of Plagger
        link: http://plagger.org/trac/browser
        revision_from: 5
        revision_to: 123
        reverse: 1
        fetch_items: 20

--- expected
is $context->update->feeds->[0]->title, 'SVN Log of Plagger';
is $context->update->feeds->[0]->link, 'http://plagger.org/trac/browser';
ok $context->update->feeds->[0]->count;
ok $context->update->feeds->[0]->entries->[0]->title;
ok $context->update->feeds->[0]->entries->[0]->link;
ok $context->update->feeds->[0]->entries->[0]->body;
