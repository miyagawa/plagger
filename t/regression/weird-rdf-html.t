use t::TestPlagger;

test_requires_network;
plan 'no_plan';
run_eval_expected;

__END__

=== RSS 1.0 with text/html
--- input config
global:
  assets_path: $FindBin::Bin/../../assets
  log:
    level: error
plugins:
  - module: Subscription::Config
    config:
      feed:
        - http://business.nikkeibp.co.jp/rss/tech.rdf
--- expected
like $context->update->feeds->[0]->title, qr/NBonline/;
