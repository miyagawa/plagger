use strict;
use FindBin;
use t::TestPlagger;

test_plugin_deps;
plan tests => 12;

run_eval_expected;

__END__
=== English atom feed with xml:lang
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/guess-language/english.xml
  - module: Filter::GuessLanguage
    config:
      target: feed
--- expected
is $context->update->feeds->[0]->language, 'en';

=== English atom feed without xml:lang
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/guess-language/english_nolang.xml
  - module: Filter::GuessLanguage
    config:
      target: feed
--- expected
is $context->update->feeds->[0]->language, 'en';

=== German atom feed with xml:lang
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/guess-language/german.xml
  - module: Filter::GuessLanguage
    config:
      target: feed
--- expected
is $context->update->feeds->[0]->language, 'de';

=== German atom feed without xml:lang
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/guess-language/german_nolang.xml
  - module: Filter::GuessLanguage
    config:
      target: feed
--- expected
is $context->update->feeds->[0]->language, 'de';

=== Japanese atom feed with xml:lang
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/guess-language/japanese.xml
  - module: Filter::GuessLanguage
    config:
      target: feed
--- expected
is $context->update->feeds->[0]->language, 'ja';

=== Japanese atom feed without xml:lang
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/guess-language/japanese_nolang.xml
  - module: Filter::GuessLanguage
    config:
      target: feed
--- expected
is $context->update->feeds->[0]->language, 'ja';

=== Mixed atom feed with xml:lang
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/guess-language/mixed.xml
  - module: Filter::GuessLanguage
    config:
      target: both
--- expected
is $context->update->feeds->[0]->entries->[0]->language, 'en';
is $context->update->feeds->[0]->entries->[1]->language, 'de';
is $context->update->feeds->[0]->entries->[2]->language, 'ja';

=== Mixed atom feed without xml:lang
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/guess-language/mixed_nolang.xml
  - module: Filter::GuessLanguage
    config:
      target: both
--- expected
is $context->update->feeds->[0]->entries->[0]->language, 'en';
is $context->update->feeds->[0]->entries->[1]->language, 'de';
is $context->update->feeds->[0]->entries->[2]->language, 'ja';
