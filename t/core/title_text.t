use t::TestPlagger;

plan 'no_plan';
run_eval_expected;

__END__

=== Test title
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/rss-full.xml
        - file://$t::TestPlagger::BaseDirURI/t/samples/tags-in-title.xml
--- expected
ok $context->update->feeds->[0]->title->is_text;
ok $_->title->is_text for $context->update->feeds->[0]->entries;

ok $context->update->feeds->[1]->title->is_text;
ok $_->title->is_html for $context->update->feeds->[1]->entries;
