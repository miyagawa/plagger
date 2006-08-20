use t::TestPlagger;

test_requires('XML::Feed', 0.11);
plan 'no_plan';
run_eval_expected;

__END__

=== use Perl atom
--- input config
global:
  assets_path: $FindBin::Bin/../../assets
  log:
    level: error
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/atom10-example.xml
--- expected
is $context->update->feeds->[0]->title, "Example Feed";
ok $context->update->feeds->[0]->link;
ok $context->update->feeds->[0]->entries->[0]->link;
