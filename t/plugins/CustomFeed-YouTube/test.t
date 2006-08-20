use strict;
use t::TestPlagger;

plan skip_all => 'The site it tries to test is unreliable.' unless $ENV{TEST_UNRELIABLE_NETWORK};
test_requires_network 'www.youtube.com:80';

plan 'no_plan';

run_eval_expected;

__END__

=== Test YouTube CustomFeed
--- input config
plugins:
  - module: CustomFeed::YouTube
    config:
      query: NBA
      sort: video_date_uploaded
      page: 1

--- expected
is $context->update->feeds->[0]->title, 'YouTube Search - NBA';
ok $context->update->feeds->[0]->count;
ok $context->update->feeds->[0]->entries->[0]->title;
ok $context->update->feeds->[0]->entries->[0]->link;
ok $context->update->feeds->[0]->entries->[0]->icon;
ok $context->update->feeds->[0]->entries->[0]->summary;
ok $context->update->feeds->[0]->entries->[0]->body;
ok $context->update->feeds->[0]->entries->[0]->author;
ok $context->update->feeds->[0]->entries->[0]->tags;
ok $context->update->feeds->[0]->entries->[0]->enclosure->url;
ok $context->update->feeds->[0]->entries->[0]->enclosure->type;
ok $context->update->feeds->[0]->entries->[0]->enclosure->filename;
