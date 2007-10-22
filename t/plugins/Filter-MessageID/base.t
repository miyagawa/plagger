use strict;
use t::TestPlagger;

test_plugin_deps;
plan 'no_plan';
run_eval_expected;

__END__

=== Loading Filter::MessageID
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/rss-full.xml
        - file://$t::TestPlagger::BaseDirURI/t/samples/rss2sample.xml
  - module: Filter::MessageID
    config:
      domain: text.plagger.example.org
--- expected
is $context->update->feeds->[0]->meta->{messageid}, '<007d5896562522fc45fc9af3d3768034_58460cb5042d256a75f6f02459752d5b@text.plagger.example.org>';
is $context->update->feeds->[1]->meta->{messageid}, '<664dba2f4306e289e00f519dc6dcd211_c646ec38faa8cb6852bea28c32fdf8f0@text.plagger.example.org>';

