use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;

plan skip_all => 'Pod coverage will warn on ALL plugins. That is not yet right';
all_pod_coverage_ok( {nonwhitespace => 1 } );

# Workaround for dumb bug (fixed in 5.8.7) where Test::Builder thinks that
# certain "die"s that happen inside evals are not actually inside evals,
# because caller() is broken if you turn on $^P like Module::Refresh does
#
# (I mean, if we've gotten to this line, then clearly the test didn't die, no?)
Test::Builder->new->{Test_Died} = 0;

