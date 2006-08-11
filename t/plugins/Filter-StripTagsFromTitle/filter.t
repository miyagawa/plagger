use strict;
use FindBin;
use t::TestPlagger;

plan tests => 2;
run_eval_expected;

__END__
=== Test without StripTagsFromTitle
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$FindBin::Bin/../../samples/tags-in-title.xml
--- expected
is $context->update->feeds->[0]->entries->[0]->title, '<b>Plagger</b> rocks';

=== Test with StripTagsFromTitle
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$FindBin::Bin/../../samples/tags-in-title.xml
  - module: Filter::StripTagsFromTitle
--- expected
is $context->update->feeds->[0]->entries->[0]->title, 'Plagger rocks';
