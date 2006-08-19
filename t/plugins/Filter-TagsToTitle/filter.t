use strict;
use t::TestPlagger;

plan tests => 5;
run_eval_expected;

__END__
=== Test without TagsToTitle
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/tags-to-title.xml
--- expected
is $context->update->feeds->[0]->entries->[0]->title, 'Plagger rocks';
is $context->update->feeds->[0]->entries->[0]->tags->[0], 'plagger';

=== Test with TagsToTitle (default)
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/tags-to-title.xml
  - module: Filter::TagsToTitle
--- expected
is $context->update->feeds->[0]->entries->[0]->title, '[plagger] Plagger rocks';

=== Test with TagsToTitle (add to explicitly left)
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/tags-to-title.xml
  - module: Filter::TagsToTitle
    config:
      add_to: left
--- expected
is $context->update->feeds->[0]->entries->[0]->title, '[plagger] Plagger rocks';

=== Test with TagsToTitle (add to right)
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/tags-to-title.xml
  - module: Filter::TagsToTitle
    config:
      add_to: right
--- expected
is $context->update->feeds->[0]->entries->[0]->title, 'Plagger rocks [plagger]';
