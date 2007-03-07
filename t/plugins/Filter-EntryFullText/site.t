use t::TestPlagger;

test_plugin_deps;
test_requires_network;

plan 'no_plan';
run_eval_expected;

__END__

===
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - http://ameblo.jp/satoeritimes/rss20.xml
  - module: Filter::EntryFullText
--- expected
unlike $context->update->feeds->[0]->entries->[0]->body, qr/\x{8457}\x{4f5c}\x{6a29}/;


