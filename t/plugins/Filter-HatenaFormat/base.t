use strict;
use t::TestPlagger;

test_plugin_deps;
plan tests => 5;
run_eval_expected;

__END__

=== Loading Filter::HatenaFormat
--- input config
plugins:
  - module: CustomFeed::Debug
    config:
      title: feed title
      entry:
        - title: test entry
          link: http://d.hatena.ne.jp/sample
          body: "* Test Entry\nThis is test entry.\n\n- foo\n- bar"
  - module: Filter::HatenaFormat
    config:
      ilevel: 1
      sectionanchor: '@'
--- expected
ok 1, $block->name;
like $context->update->feeds->[0]->entries->[0]->body, qr{<div class="section">.*</div>}s;
like $context->update->feeds->[0]->entries->[0]->body, qr{<h3>.*Test Entry</h3>};
like $context->update->feeds->[0]->entries->[0]->body, qr{<span class="sanchor">@</span>};
like $context->update->feeds->[0]->entries->[0]->body, qr{<ul>.*<li> foo</li>.*<li> bar</li>.*</ul>}s;
