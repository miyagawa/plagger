use strict;
use t::TestPlagger;

plan tests => 4;
run_eval_expected;

__END__
=== Test without AddTags
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/rss-20.xml
--- expected
ok !$context->update->feeds->[0]->entries->[0]->tags->[0];

=== Test with AddTags
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/rss-20.xml
  - module: Filter::AddTags
    config:
      tags:
        - plagger_rocks
--- expected
is $context->update->feeds->[0]->entries->[0]->tags->[0], 'plagger_rocks';

=== Test with AddTags (with 2 tags)
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/rss-20.xml
  - module: Filter::AddTags
    config:
      tags:
        - plagger_rocks
        - plagger_rocks_more
--- expected
is $context->update->feeds->[0]->entries->[0]->tags->[0], 'plagger_rocks';
is $context->update->feeds->[0]->entries->[0]->tags->[1], 'plagger_rocks_more';