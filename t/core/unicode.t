use strict;
use t::TestPlagger;

plan 'no_plan';
run_eval_expected;

__END__

=== Test Unicode
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDir/t/samples/rss-full.xml
--- expected
ok utf8::is_utf8( $context->update->feeds->[0]->title );
ok utf8::is_utf8( $context->update->feeds->[0]->description );
ok utf8::is_utf8( $context->update->feeds->[0]->entries->[0]->title );
ok utf8::is_utf8( $context->update->feeds->[0]->entries->[0]->body );
