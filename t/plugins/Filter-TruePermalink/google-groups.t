use t::TestPlagger;

test_requires_network;
plan 'no_plan';
run_eval_expected;

__END__

=== Google Groups
--- input config
plugins:
  - module: CustomFeed::Debug
    config:
      title: Foo
      entry:
        - title: Foo
          link: http://groups.google.co.jp/group/plagger-dev/msg/235d0379ead509ed
  - module: Filter::TruePermalink
--- expected
unlike $context->update->feeds->[0]->entries->[0]->permalink, qr/google\.co\.jp/;
like $context->update->feeds->[0]->entries->[0]->permalink, qr/google\.com/;
