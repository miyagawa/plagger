use strict;
use FindBin;

use t::TestPlagger;

test_requires('HTTP::Cookies::Mozilla');

plan tests => 6;
run_eval_expected;

package Plagger::Plugin::Test::Cookies;
use base qw( Plagger::Plugin );
use Plagger::UserAgent;

sub register {
    my($self, $context) = @_;
    $context->register_hook(
        $self,
        'plugin.init' => \&test,
    );
}

sub test {
    my($self, $context, $args) = @_;

    my $ua = Plagger::UserAgent->new;
    ::isa_ok $ua->cookie_jar, 'HTTP::Cookies::Mozilla';

    $ua->cookie_jar->scan(
        sub {
            my($key, $val) = @_[1,2];
            ::is $key, 'key';
            ::is $val, 'foobar';
        },
    );
}

__END__

=== cookies: filename
--- input config
global:
  log:
    level: error
  user_agent:
    cookies: $FindBin::Bin/cookies.txt
plugins:
  - module: Test::Cookies
--- expected
1

=== cookies: hash
--- input config
global:
  log:
    level: error
  user_agent:
    cookies:
      type: Mozilla
      file: $FindBin::Bin/cookies.txt
plugins:
  - module: Test::Cookies
--- expected
1
