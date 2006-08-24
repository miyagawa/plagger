use t::TestPlagger;

test_requires_network;
plan 'no_plan';
run_eval_expected;

__END__

=== oreilly
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - http://www.makezine.com/
  - module: Filter::TruePermalink
--- expected
unlike $context->update->feeds->[0]->entries->[0]->permalink, qr/CMP=/;
