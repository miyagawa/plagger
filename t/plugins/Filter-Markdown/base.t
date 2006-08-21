use strict;
use t::TestPlagger;

test_plugin_deps;
plan tests => 5;
run_eval_expected;

__END__

=== Loading Filter::Markdown
--- input config
plugins:
  - module: CustomFeed::Debug
    config:
      title: feed title
      entry:
        - title: test entry
          link: http://blog.example.com/sample
          body: "This is an H1\n=============\n## This is an H2\n\n > blockquote\n\n + foo\n + bar\n"
  - module: Filter::Markdown
    config:
      empty_element_suffix: ' />'
      tab_width: '4'
--- expected
ok 1, $block->name;
like $context->update->feeds->[0]->entries->[0]->body, qr{<h1>This is an H1</h1>};
like $context->update->feeds->[0]->entries->[0]->body, qr{<h2>This is an H2</h2>};
like $context->update->feeds->[0]->entries->[0]->body, qr{<blockquote>.*blockquote.*</blockquote>}s;
like $context->update->feeds->[0]->entries->[0]->body, qr{<ul>.*<li>foo</li>.*<li>bar</li>.*</ul>}s;
