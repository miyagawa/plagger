use strict;
use t::TestPlagger;

test_requires_network;

plan 'no_plan';

run_eval_expected;

__END__

=== Test Flickr Search
--- input config
plugins:
  - module: CustomFeed::FlickrSearch
    config:
     api_key: 84155d786cb2bb23b78ee124a5a8a988
     method: flickr.photos.search
     params:
       tags: plagger

--- expected
is $context->update->feeds->[0]->type, 'flickr.search';
ok $context->update->feeds->[0]->count;
ok $context->update->feeds->[0]->entries->[0]->title;
ok $context->update->feeds->[0]->entries->[0]->link;
ok $context->update->feeds->[0]->entries->[0]->icon;
ok $context->update->feeds->[0]->entries->[0]->author;
ok $context->update->feeds->[0]->entries->[0]->tags;
ok $context->update->feeds->[0]->entries->[0]->enclosure->url;
ok $context->update->feeds->[0]->entries->[0]->enclosure->type;
ok $context->update->feeds->[0]->entries->[0]->enclosure->filename;
