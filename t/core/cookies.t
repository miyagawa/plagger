use strict;
use Test::More tests => 6;
use FindBin;

use Plagger;

# cookies: filename
Plagger->bootstrap(config => \<<CONFIG);
global:
  log:
    level: error
  user_agent:
    cookies: $FindBin::Bin/cookies.txt
plugins:
  - module: Test::Cookies
CONFIG

# cookies: hash
Plagger->bootstrap(config => \<<CONFIG);
global:
  log:
    level: error
  user_agent:
    cookies:
      type: Mozilla
      file: $FindBin::Bin/cookies.txt
plugins:
  - module: Test::Cookies
CONFIG

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

