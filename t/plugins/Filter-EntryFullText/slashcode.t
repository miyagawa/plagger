use t::TestPlagger;

test_plugin_deps;
test_requires_network;

plan 'no_plan';
run_eval_expected;

__END__

=== Test use Perl journal
--- input config
plugins:
  - module: CustomFeed::Debug
    config:
      title: slashcode
      entry:
        - title: use perl
          link: http://use.perl.org/~Adrian/journal/30717
  - module: Filter::EntryFullText
--- expected
ok $context->update->feeds->[0]->entries->[0]->body;

