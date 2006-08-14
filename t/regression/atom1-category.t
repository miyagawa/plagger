use t::TestPlagger;

test_requires('XML::Atom', 0.20);
plan 'no_plan';
run_eval_expected;

__END__

=== Atom 1.0 with categories
--- input config
global:
  log:
    level: error
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/atom-category.xml
--- expected
is_deeply scalar $context->update->feeds->[0]->entries->[0]->tags, [ 'Catalyst' ];
is_deeply scalar $context->update->feeds->[0]->entries->[1]->tags, [ 'Catalyst', 'Programming' ];
is $context->update->feeds->[0]->entries->[0]->date->epoch, 1155150478;

