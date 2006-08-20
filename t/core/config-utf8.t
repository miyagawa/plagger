use strict;
use t::TestPlagger;

plan 'no_plan';
run_eval_expected;

__END__

=== Auto decode utf-8
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - url: file://$t::TestPlagger::BaseDirURI/t/samples/rss-full.xml
          title: テストフィード
          tag: テスト
--- expected
ok utf8::is_utf8( $context->update->feeds->[0]->tags->[0] );

=== No auto decode
--- input config
global:
  no_decode_utf8: 1
plugins:
  - module: Subscription::Config
    config:
      feed:
        - url: file://$t::TestPlagger::BaseDirURI/t/samples/rss-full.xml
          title: テストフィード
          tag: テスト
--- expected
ok !utf8::is_utf8( $context->update->feeds->[0]->tags->[0] );
