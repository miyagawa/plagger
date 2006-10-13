use strict;
use t::TestPlagger;

test_plugin_deps;
plan 'no_plan';
run_eval_expected;

__END__

=== Loading Summary::English
--- input config
plugins:
  - module: Summary::English
--- expected
ok 1, $block->name;

=== Big Text in HTML
--- input config
plugins:
  - module: CustomFeed::Debug
    config:
      title: Foo
      entry:
        - title: Hello World
          body: |
            <p>The YAML.pm module implements a YAML Loader and Dumper based on the YAML 1.0 specification.</p>
            <p>YAML is a generic data serialization language that is optimized for human readability. It can be
            used to express the data structures of most modern programming languages. (Including Perl!!!)
            For information on the YAML syntax, please refer to the YAML specification.</p>
  - module: Summary::English
--- expected
is $context->update->feeds->[0]->entries->[0]->summary->type, 'text';
like $context->update->feeds->[0]->entries->[0]->summary->data, qr/YAML is a generic data serialization language that is optimized for human readability./;
