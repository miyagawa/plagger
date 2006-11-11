use t::TestPlagger;

test_plugin_deps;
test_requires_network;

plan 'no_plan';
run_eval_expected;

__END__

=== Test MT 2.x site
--- input config
plugins:
  - module: CustomFeed::Debug
    config:
      title: MT 2.x
      entry:
        - title: foo
          link: http://funapon.info/chri/archives/003623.html
  - module: Filter::EntryFullText
--- expected
like $context->update->feeds->[0]->entries->[0]->body, qr/<p>/;
