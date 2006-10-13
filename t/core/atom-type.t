use strict;
use t::TestPlagger;

plan skip_all => "This test is broke until XML::Atom and XML::Feed is updated to handle Atom 1.0 text construct properly.";
plan 'no_plan';
run_eval_expected;

__END__

=== Test Atom type
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/atom-type.xml

--- expected
is $context->update->feeds->[0]->entries->[0]->summary->type, 'text', 'type=text';
is $context->update->feeds->[0]->entries->[0]->summary->type, 'text', 'type=text';
is $context->update->feeds->[0]->entries->[1]->summary->type, 'html', 'type=html';
is $context->update->feeds->[0]->entries->[1]->summary->type, 'html', 'type=html';
