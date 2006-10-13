use strict;
use t::TestPlagger;

test_plugin_deps;
plan 'no_plan';
run_eval_expected;

__END__

=== Loading Summary::TextOriginal
--- input config
plugins:
  - module: Summary::TextOriginal
--- expected
ok 1, $block->name;

=== Big Text
--- input config
plugins:
  - module: CustomFeed::Debug
    config:
      title: Foo
      entry:
        - title: Hello World
          body: |
            The YAML.pm module implements a YAML Loader and Dumper based on the YAML 1.0 specification.
            
            YAML is a generic data serialization language that is optimized for human readability. It can be
            used to express the data structures of most modern programming languages. (Including Perl!!!)
            For information on the YAML syntax, please refer to the YAML specification.
  - module: Summary::TextOriginal
--- expected
is $context->update->feeds->[0]->entries->[0]->summary->type, 'text';
is $context->update->feeds->[0]->entries->[0]->summary->data, 'The YAML.pm module implements a YAML Loader and Dumper based on the YAML 1.0 specification.';

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
  - module: Summary::TextOriginal
--- expected
is $context->update->feeds->[0]->entries->[0]->summary->type, 'text';
like $context->update->feeds->[0]->entries->[0]->summary->data, qr/The YAML.pm module implements a YAML Loader and Dumper based on the YAML\s+1.0 specification./;

