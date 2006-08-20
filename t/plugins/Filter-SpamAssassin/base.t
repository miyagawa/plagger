use strict;
use t::TestPlagger;

test_plugin_deps;
plan 'no_plan';
run_eval_expected;

__END__

=== Filter::SpamAssassin: make entries to be considered as spams
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/atom10-example.xml
  - module: Filter::SpamAssassin
    config:
      new:
        local_tests_only: 1
        dont_copy_prefs: 1
#       debug: 1
        site_rules_filename: $t::TestPlagger::BaseDir/t/samples/spamassassin/spam_rule.txt
--- expected
ok $context->update->feeds->[0]->entries->[0]->tags->[0] eq 'spam';

=== Filter::SpamAssassin: report test
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/atom10-example.xml
  - module: Filter::SpamAssassin
    config:
      add_report: 1
      new:
        local_tests_only: 1
        dont_copy_prefs: 1
#       debug: 1
        site_rules_filename: $t::TestPlagger::BaseDir/t/samples/spamassassin/spam_rule.txt
--- expected
ok $context->update->feeds->[0]->entries->[0]->tags->[0] eq 'spam';
like $context->update->feeds->[0]->entries->[0]->body_text, qr/NO_RELAYS/;

=== Filter::SpamAssassin: hopefully considered as hams
--- input config
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/atom10-example.xml
  - module: Filter::SpamAssassin
    config:
      new:
        local_tests_only: 1
        dont_copy_prefs: 1
#       debug: 1
        site_rules_filename: $t::TestPlagger::BaseDir/t/samples/spamassassin/ham_rule.txt
--- expected
ok !@{ $context->update->feeds->[0]->entries->[0]->tags };
