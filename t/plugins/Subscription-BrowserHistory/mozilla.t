use strict;
use t::TestPlagger;

test_plugin_deps('Subscription::BrowserHistory::Mozilla');
plan tests => 4;
run_eval_expected;

__END__

=== test file
--- input config
plugins:
  - module: Subscription::BrowserHistory
    config:
      browser: Mozilla
      path: $t::TestPlagger::BaseDirURI/t/samples/mozilla-history.dat

  - module: Aggregator::Null
--- expected
is $context->subscription->feeds->[0]->url, "http://etudiant.epitech.net/~bret_a/limecat/limecat-4.jpg";
is $context->subscription->feeds->[0]->title, "limecat-4.jpg (JPEG Image, 571x435 pixels)";
is $context->subscription->feeds->[1]->url, "http://etudiant.epitech.net/~bret_a/limecat/";
is $context->subscription->feeds->[1]->title, "Limecat";

