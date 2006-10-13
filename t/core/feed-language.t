use strict;
use t::TestPlagger;

test_requires('XML::Atom', 0.22);

plan 'no_plan';
run_eval_expected;

__END__

=== feed xml:lang
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/atom10-example.xml
--- expected
is $context->update->feeds->[0]->language, 'en';
is $context->update->feeds->[0]->entries->[0]->language, undef;
is $context->update->feeds->[0]->entries->[1]->language, 'ja';
