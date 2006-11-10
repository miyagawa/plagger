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

=== Enclosures
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
          enclosure:
            url: http://example.com/foo.mp3
            length: 123
            type: audio/mp3

        - title: 'First Entry'
          link: 'http://localhost/1'
          body: 'Hello World! :)'
          enclosure:
            - url: http://example.com/foo.mp3
              length: 123
            - url: http://example.com/foo.m4a
              length: 456
--- expected
is $context->update->feeds->[0]->link, 'http://localhost/';
is $context->update->feeds->[0]->title, 'My Feed';
{
    my @e = $context->update->feeds->[0]->entries->[0]->enclosures;
    is @e, 1;
    isa_ok $e[0]->url, 'URI';
    is $e[0]->url, 'http://example.com/foo.mp3';
    is $e[0]->type, 'audio/mp3';
    is $e[0]->length, 123;
}
{
    my @e = $context->update->feeds->[0]->entries->[1]->enclosures;
    is @e, 2;
    isa_ok $e[0]->url, 'URI';
    is $e[0]->url, 'http://example.com/foo.mp3';
    is $e[0]->type, 'audio/mpeg';
    is $e[0]->length, 123;
    is $e[1]->url, 'http://example.com/foo.m4a';
    is $e[1]->type, 'audio/aac';
    is $e[1]->length, 456;
}


