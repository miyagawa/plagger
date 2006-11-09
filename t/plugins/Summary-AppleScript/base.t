use strict;
use t::TestPlagger;

test_plugin_deps;
plan 'no_plan';
run_eval_expected;

__END__

=== Loading Summary::AppleScript
--- input config
plugins:
  - module: Summary::AppleScript
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
  - module: Summary::AppleScript
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
            <p>The <a href="http://search.cpan.org/dist/YAML/"><img src="http://www.yaml.org/img/page_backdrop.gif">YAML.pm</a> module implements a &quot;YAML Loader&quot; and Dumper based on the YAML 1.0 specification.</p>
            <p>YAML is a generic data serialization language that is optimized for human readability. It can be
            used to express the data structures of most modern programming languages. (Including Perl!!!)
            For information on the YAML syntax, please refer to the YAML specification.</p>
  - module: Summary::AppleScript
--- expected
is $context->update->feeds->[0]->entries->[0]->summary->type, 'text';
like $context->update->feeds->[0]->entries->[0]->summary->data, qr/The \[IMAGE\]YAML\.pm module implements a "YAML Loader" and Dumper based on the YAML\s+1\.0 specification\./;
