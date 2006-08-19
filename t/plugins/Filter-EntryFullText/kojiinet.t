use t::TestPlagger;

test_plugin_deps;
test_requires 'HTML::TreeBuilder::XPath';
test_requires_network 'www.kojii.net:80';

plan 'no_plan';
run_eval_expected;

__END__

=== Test kojii.net XPath
--- input config
plugins:
  - module: CustomFeed::Debug
    config:
      title: foo
      entry:
        - title: foo
          link:  http://www.kojii.net/opinion/col051003.html
  - module: Filter::EntryFullText
--- expected
unlike $context->update->feeds->[0]->entries->[0]->body, qr/&#x\d+;/;

