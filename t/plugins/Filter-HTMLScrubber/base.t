use strict;
use t::TestPlagger;

test_plugin_deps;
plan 'no_plan';
run_eval_expected;

__END__

=== Loading Filter::HTMLScrubber
--- input config
plugins:
  - module: CustomFeed::Debug
    config:
      title: foo
      link: 'http://www.example.net/'
      entry:
        - title: bar
          link: 'http://www.example.net/1'
          body: |
            <script type="text/javascript">
            function pla() {
                alert("Plagger is a pluggable aggregator");
            }
            </script>
            <p>
                <a href="#" onclick="pla()">Plagger is a pluggable aggregator</a>
            </p>
  - module: Filter::HTMLScrubber
--- expected
ok 1, $block->name;
unlike $context->update->feeds->[0]->entries->[0]->body, qr!</?script .*?>!sm;

