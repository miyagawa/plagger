use strict;
use t::TestPlagger;

test_requires_network('mizzy.org:80');

plan 'no_plan';

run_eval_expected;

__END__

=== Test Filter::HEADEnclosureMetadata
--- input config
plugins:
  - module: CustomFeed::Debug
    config:
      title: 'Test Filter::HEADEnclosureMetadata'
      link: 'http://mizzy.org/plagger-test/'
      entry:
        - title: 'First Entry'
          link: 'http://mizzy.org/plagger-test/'
          body: 'Test Filter::HEADEnclosureMetadata'
          summary: 'Test Filter::HEADEnclosureMetadata'
          author: 'Gosuke Miyashita <gosukenator@gmail.com>'
          enclosure:
            - url: http://mizzy.org/plagger-test/mizzy.flv

  - module: Filter::HEADEnclosureMetadata

--- expected
is $context->update->feeds->[0]->entries->[0]->enclosure->filename, 'mizzy.flv';
is $context->update->feeds->[0]->entries->[0]->enclosure->type, 'video/x-flv';
is $context->update->feeds->[0]->entries->[0]->enclosure->length, '242946';
