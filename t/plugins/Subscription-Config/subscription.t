use strict;
use t::TestPlagger;

plan tests => 1;
run_eval_expected;

__END__

=== test file
--- input config 
plugins:
  - module: Subscription::Config
    config:
      feed:
        - url: http://bulknews.typepad.com/blog/atom.xml
        - url: http://blog.bulknews.net/mt/index.rdf
  - module: Aggregator::Null
--- expected
my @feeds = map $_->url, $context->subscription->feeds;
is_deeply(
    \@feeds,
    [ 'http://bulknews.typepad.com/blog/atom.xml',
      'http://blog.bulknews.net/mt/index.rdf']
);
